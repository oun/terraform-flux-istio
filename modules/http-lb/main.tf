terraform {
  backend "gcs" {}
  required_version = "= 0.12.26"

  required_providers {
    google     = "= 3.25.0"
  }
}

locals {
  address = var.create_address ? join("", google_compute_global_address.default.*.address) : var.address
}

resource "google_compute_global_forwarding_rule" "http" {
  project    = var.project
  count      = var.http_forward ? 1 : 0
  name       = var.name
  target     = google_compute_target_http_proxy.default[0].self_link
  ip_address = local.address
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "https" {
  project    = var.project
  count      = var.ssl ? 1 : 0
  name       = "${var.name}-https"
  target     = google_compute_target_https_proxy.default[0].self_link
  ip_address = local.address
  port_range = "443"
}

resource "google_compute_global_address" "default" {
  count        = var.create_address ? 1 : 0
  project      = var.project
  name         = "${var.name}-address"
  ip_version   = var.ip_version
}

# HTTP proxy when http forwarding is true
resource "google_compute_target_http_proxy" "default" {
  project = var.project
  count   = var.http_forward ? 1 : 0
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

# HTTPS proxy when ssl is true
resource "google_compute_target_https_proxy" "default" {
  project = var.project
  count   = var.ssl ? 1 : 0
  name    = "${var.name}-https-proxy"
  url_map = google_compute_url_map.default.self_link

  ssl_certificates = compact(concat(var.ssl_certificates, google_compute_ssl_certificate.default.*.self_link, ), )
  ssl_policy       = var.ssl_policy
  quic_override    = var.quic ? "ENABLE" : null
}

resource "google_compute_ssl_certificate" "default" {
  project     = var.project
  count       = var.ssl && ! var.use_ssl_certificates ? 1 : 0
  name_prefix = "${var.name}-certificate-"
  private_key = var.private_key
  certificate = var.certificate

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_url_map" "default" {
  name            = var.name
  default_service = var.default_service != null ? (length(google_compute_backend_service.services) > 0 ? google_compute_backend_service.services[var.default_service].self_link : google_compute_backend_bucket.buckets[var.default_service].self_link) : null

  dynamic "host_rule" {
    for_each = var.bucket_backends
    content {
      hosts        = host_rule.value.hosts
      path_matcher = "${host_rule.key}-paths"
    }
  }

  dynamic "host_rule" {
    for_each = var.service_backends
    content {
      hosts        = host_rule.value.hosts
      path_matcher = "${host_rule.key}-paths"
    }
  }

  dynamic "path_matcher" {
    for_each = var.bucket_backends

    content {
      name = "${path_matcher.key}-paths"
      default_service = google_compute_backend_bucket.buckets[path_matcher.key].self_link
    }
  }

  dynamic "path_matcher" {
    for_each = var.service_backends

    content {
      name = "${path_matcher.key}-paths"
      default_service = google_compute_backend_service.services[path_matcher.key].self_link
    }
  }

  dynamic "default_url_redirect" {
    for_each = var.redirect_https ? [1]: []
    content {
      https_redirect         = true
      redirect_response_code = var.redirect_response_code
      strip_query            = false
    }
  }
}

resource "google_compute_backend_bucket" "buckets" {
  for_each    = var.bucket_backends
  name        = "${var.name}-${each.key}-backend"
  description = lookup(each.value, "description", null)
  bucket_name = each.value.bucket
  enable_cdn  = lookup(each.value, "enable_cdn", true)
}

resource "google_compute_backend_service" "services" {
  provider = google-beta
  for_each = var.service_backends

  project = var.project
  name    = "${var.name}-${each.key}-backend"

  port_name                       = each.value.port_name
  protocol                        = each.value.protocol
  timeout_sec                     = lookup(each.value, "timeout_sec", 30)
  description                     = lookup(each.value, "description", null)
  connection_draining_timeout_sec = lookup(each.value, "connection_draining_timeout_sec", 300)
  enable_cdn                      = lookup(each.value, "enable_cdn", false)
  security_policy                 = var.security_policy
  health_checks                   = [google_compute_health_check.default[each.key].self_link]
  session_affinity                = lookup(each.value, "session_affinity", "NONE")
  affinity_cookie_ttl_sec         = lookup(each.value, "affinity_cookie_ttl_sec", null)

  dynamic "backend" {
    for_each = toset(each.value["groups"])

    content {
      balancing_mode               = lookup(backend.value, "balancing_mode", "RATE")
      capacity_scaler              = lookup(backend.value, "capacity_scaler", 1.0)
      description                  = lookup(backend.value, "description", null)
      group                        = lookup(backend.value, "group", null)
      max_connections              = lookup(backend.value, "max_connections", null)
      max_connections_per_instance = lookup(backend.value, "max_connections_per_instance", null)
      max_connections_per_endpoint = lookup(backend.value, "max_connections_per_endpoint", null)
      max_rate                     = lookup(backend.value, "max_rate", null)
      max_rate_per_instance        = lookup(backend.value, "max_rate_per_instance", null)
      max_rate_per_endpoint        = lookup(backend.value, "max_rate_per_endpoint", null)
      max_utilization              = lookup(backend.value, "max_utilization", null)
    }
  }

  log_config {
    enable      = lookup(lookup(each.value, "log_config", {}), "enable", true)
    sample_rate = lookup(lookup(each.value, "log_config", {}), "sample_rate", "1.0")
  }

  depends_on = [google_compute_health_check.default]
}

resource "google_compute_health_check" "default" {
  provider = google-beta
  for_each = var.service_backends
  project  = var.project
  name     = "${var.name}-hc-${each.key}"

  check_interval_sec  = lookup(each.value["health_check"], "check_interval_sec", 5)
  timeout_sec         = lookup(each.value["health_check"], "timeout_sec", 5)
  healthy_threshold   = lookup(each.value["health_check"], "healthy_threshold", 2)
  unhealthy_threshold = lookup(each.value["health_check"], "unhealthy_threshold", 2)

  log_config {
    enable = lookup(each.value["health_check"], "logging", false)
  }

  http_health_check {
    host         = lookup(each.value["health_check"], "host", null)
    request_path = lookup(each.value["health_check"], "request_path", null)
    port         = lookup(each.value["health_check"], "port", null)
  }
}

resource "google_compute_firewall" "default-hc" {
  count   = length(var.firewall_networks)
  project = length(var.firewall_networks) == 1 && var.firewall_projects[0] == "default" ? var.project : var.firewall_projects[count.index]
  name    = "allow-health-check-${var.name}-${count.index}"
  network = var.firewall_networks[count.index]
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  target_tags             = length(var.target_tags) > 0 ? var.target_tags : null
  target_service_accounts = length(var.target_service_accounts) > 0 ? var.target_service_accounts : null

  dynamic "allow" {
    for_each = var.service_backends
    content {
      protocol = "tcp"
      ports    = [allow.value.port]
    }
  }
}
