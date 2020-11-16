terraform {
  source = "../../../modules//http-lb"
}

include {
  path = find_in_parent_folders()
}

dependency "neg" {
  config_path = "../istio-neg"
  mock_outputs = {
    name  = "mock-neg"
    zones = []
  }
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  project  = local.env_vars.locals.project
}

inputs = {
  name           = "https-lb"
  create_address = true

  service_backends = {
    "demo-service-backend" = {
      description                     = "Demo service backend"
      hosts                           = ["terraform-flux-istio.dev"]
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 600
      connection_draining_timeout_sec = 300
      enable_cdn                      = false
      session_affinity                = "NONE"
      affinity_cookie_ttl_sec         = null

      health_check = {
        check_interval_sec  = 15
        timeout_sec         = 15
        healthy_threshold   = 1
        unhealthy_threshold = 2
        host                = null
        request_path        = "/"
        port                = 80
        logging             = false
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [for zone in dependency.neg.outputs.zones:
      {
        group                        = "https://www.googleapis.com/compute/v1/projects/${local.project}/zones/${zone}/networkEndpointGroups/${dependency.neg.outputs.name}"
        description                  = "Demo Network Endpoint Group"
        balancing_mode               = "RATE"
        capacity_scaler              = 1.0
        max_rate_per_endpoint        = 80
        max_connections              = null
        max_connections_per_instance = null
        max_connections_per_endpoint = null
        max_rate                     = null
        max_rate_per_instance        = null
        max_utilization              = null
      }]
    }
  }
  default_service      = "demo-service-backend"
  firewall_networks    = ["default"]
  firewall_projects    = ["default"]
  http_forward         = true
  ssl                  = false
  use_ssl_certificates = false
}