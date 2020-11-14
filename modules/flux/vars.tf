variable "project" {
  type        = string
  description = "The project ID to host the cluster in (required)"
}

variable "cluster_endpoint" {
  type        = string
  description = "Cluster endpoint"
}

variable "cluster_ca_certificate" {
  type        = string
  description = "Cluster CA certificate"
}

variable "flux_namespace" {
  type        = string
  description = "Flux namespace"
  default     = "flux"
}

variable "flux_git_private_key" {
  type        = string
  description = "Flux git deploy private key"
}

variable "flux_git_repo" {
  type        = string
  description = "URL of git repo"
}

variable "flux_git_branch" {
  type        = string
  description = "Branch of git repo"
  default     = "master"
}

variable "flux_git_path" {
  type        = list(string)
  description = "Path within git repo to locate Kubernetes manifests (relative path)"
}

variable "flux_git_poll_interval" {
  type        = string
  description = "Period at which to fetch any new commits from the git repo"
  default     = "1m"
}

variable "flux_registry_poll_interval" {
  type        = string
  description = "Period at which to check for updated images"
  default     = "5m"
}

variable "flux_registry_rps" {
  type        = number
  description = "Maximum registry requests per second per host"
  default     = 20
}
