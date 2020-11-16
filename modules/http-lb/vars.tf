variable "project" {
  description = "The project to deploy to, if not set the default provider project is used."
  type        = string
}

variable "create_address" {
  type        = bool
  description = "Create a new global address"
  default     = true
}

variable "address" {
  type        = string
  description = "IP address self link"
  default     = null
}

variable "name" {
  description = "Name for the forwarding rule and prefix for supporting resources"
  type        = string
}

variable "http_forward" {
  description = "Set to `false` to disable HTTP port 80 forward"
  type        = bool
  default     = true
}

variable "ip_version" {
  description = "IP version for the Global address (IPv4 or v6) - Empty defaults to IPV4"
  type        = string
  default     = null
}

variable "ssl" {
  description = "Set to `true` to enable SSL support, requires variable `ssl_certificates` - a list of self_link certs"
  type        = bool
  default     = false
}

variable "ssl_policy" {
  type        = string
  description = "Selfink to SSL Policy"
  default     = null
}

variable "ssl_certificates" {
  description = "SSL cert self_link list. Required if `ssl` is `true` and no `private_key` and `certificate` is provided."
  type        = list(string)
  default     = []
}

variable "quic" {
  type        = bool
  description = "Set to `true` to enable QUIC support"
  default     = false
}

variable "private_key" {
  description = "Content of the private SSL key. Required if `ssl` is `true` and `ssl_certificates` is empty."
  type        = string
  default     = null
}

variable "certificate" {
  description = "Content of the SSL certificate. Required if `ssl` is `true` and `ssl_certificates` is empty."
  type        = string
  default     = null
}

variable "use_ssl_certificates" {
  description = "If true, use the certificates provided by `ssl_certificates`, otherwise, create cert from `private_key` and `certificate`"
  type        = bool
  default     = false
}

variable "security_policy" {
  description = "The resource URL for the security policy to associate with the backend service"
  type        = string
  default     = null
}

variable "service_backends" {
  description = "Map backend indices to list of backend maps."
  type = map(object({
    description                     = string
    hosts                           = list(string)
    protocol                        = string
    port                            = number
    port_name                       = string
    timeout_sec                     = number
    connection_draining_timeout_sec = number
    enable_cdn                      = bool
    session_affinity                = string
    affinity_cookie_ttl_sec         = number
    health_check = object({
      check_interval_sec  = number
      timeout_sec         = number
      healthy_threshold   = number
      unhealthy_threshold = number
      request_path        = string
      port                = number
      host                = string
      logging             = bool
    })
    log_config = object({
      enable      = bool
      sample_rate = number
    })
    groups = list(object({
      group                        = string
      balancing_mode               = string
      capacity_scaler              = number
      description                  = string
      max_connections              = number
      max_connections_per_instance = number
      max_connections_per_endpoint = number
      max_rate                     = number
      max_rate_per_instance        = number
      max_rate_per_endpoint        = number
      max_utilization              = number
    }))
  }))
  default = {}
}

variable "bucket_backends" {
  description = "Bucket url map"
  type        = map(object({
    hosts      = list(string)
    bucket     = string
    enable_cdn = bool
  }))
  default = {}
}

variable "default_service" {
  description = "Default backend service"
  type        = string
  default     = null
}

variable "firewall_networks" {
  description = "Names of the networks to create firewall rules in"
  type        = list(string)
  default     = []
}

variable "firewall_projects" {
  description = "Names of the projects to create firewall rules in"
  type        = list(string)
  default     = []
}

variable "target_tags" {
  description = "List of target tags for health check firewall rule. Exactly one of target_tags or target_service_accounts should be specified."
  type        = list(string)
  default     = []
}

variable "target_service_accounts" {
  description = "List of target service accounts for health check firewall rule. Exactly one of target_tags or target_service_accounts should be specified."
  type        = list(string)
  default     = []
}

variable "redirect_https" {
  description = "Redirect to https"
  type        = bool
  default     = false
}

variable "redirect_response_code" {
  description = "The HTTP Status code to use for redirect"
  type        = string
  default     = "MOVED_PERMANENTLY_DEFAULT"
}
