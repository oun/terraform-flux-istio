variable "region" {
  description = "The GCP region to use."
  type        = string
  default     = null
}

variable "project" {
  description = "The ID of the project in which the resource belongs to."
  type        = string
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster (required)"
}

variable "cluster_endpoint" {
  type        = string
  description = "Cluster endpoint"
}

variable "cluster_ca_certificate" {
  type        = string
  description = "Cluster CA certificate"
}

variable "namespace" {
  description = "Kubernetes service namespace"
  type        = string
}