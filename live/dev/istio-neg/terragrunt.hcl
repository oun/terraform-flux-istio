terraform {
  source = "../../../modules//istio-neg?ref=master"
}

include {
  path = find_in_parent_folders()
}

dependency "gke" {
  config_path = "../gke"
}

dependencies {
  paths = ["../flux"]
}

inputs = {
  cluster_name           = dependency.gke.outputs.name
  region                 = dependency.gke.outputs.region
  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate
  namespace              = "istio-system"
}