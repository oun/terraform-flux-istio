terraform {
  source = "../../../modules//istio-neg?ref=master"
}

include {
  path = find_in_parent_folders()
}

dependency "gke" {
  config_path = "../gke"
  mock_outputs = {
    name            = "mock"
    type            = "zonal"
    location        = "asia-southeast1"
    endpoint        = "mock"
    ca_certificate  = ""
  }
}

dependencies {
  paths = ["../flux"]
}

inputs = {
  cluster_name           = dependency.gke.outputs.name
  cluster_type           = dependency.gke.outputs.type
  cluster_location       = dependency.gke.outputs.location
  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate
  namespace              = "istio-system"
}