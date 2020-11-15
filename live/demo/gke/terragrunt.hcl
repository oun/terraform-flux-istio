terraform {
  source = "../../../modules//gke?ref=master"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  kubernetes_version               = "latest"
  kubernetes_version_prefix        = "1.16."
  name                             = "gitops-istio-demo"
  description                      = "GitOps Istio Demo"
  regional                         = false
  region                           = "asia-southeast1"
  zones                            = ["asia-southeast1-a"]
  http_load_balancing              = true
  maintenance_start_time           = "19:00"
  initial_node_count               = "1"
  network                          = "default"
  subnetwork                       = "default"
  issue_client_certificate         = true
  enable_workload_identity         = false
  remove_default_node_pool         = true
  default_max_pods_per_node        = 64
  node_pools = [
    {
      name              = "node-pool-1"
      machine_type      = "n1-standard-4"
      autoscaling       = true
      min_count         = 1
      max_count         = 3
      disk_size_gb      = 30
      disk_type         = "pd-standard"
      image_type        = "COS"
      auto_repair       = false
      preemptible       = true
    }
  ]
  master_authorized_networks = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "Any"
    },
  ]
  node_pools_tags = {
    node-pool-1 = ["gke-node"]
  }
  cluster_resource_labels = {
    maintained-by = "terraform"
  }
}