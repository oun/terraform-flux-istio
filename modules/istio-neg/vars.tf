variable "cluster_type" {
  description = "Cluster type (regional / zonal)"
  type        = string
  default     = "zonal"
}

variable "cluster_location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
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