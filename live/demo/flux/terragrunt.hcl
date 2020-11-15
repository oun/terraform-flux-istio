terraform {
  source = "../../../modules//flux"
}

include {
  path = find_in_parent_folders()
}

dependency "gke" {
  config_path = "../gke"
  mock_outputs = {
    endpoint       = "mock"
    ca_certificate = "mock"
  }
}

inputs = {
  cluster_endpoint            = dependency.gke.outputs.endpoint
  cluster_ca_certificate      = dependency.gke.outputs.ca_certificate
  flux_git_repo               = "git@github.com:oun/terraform-flux-istio.git"
  flux_namespace              = "flux"
  flux_git_private_key        = "./git_private_key"
  flux_git_path               = ["app", "istio"]
  flux_registry_poll_interval = "2m"
  flux_registry_rps           = 30
}