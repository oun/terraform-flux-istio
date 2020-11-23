terraform {
  backend "gcs" {}
  required_version = "= 0.12.26"

  required_providers {
    google     = "= 3.25.0"
  }
}

provider "kubernetes" {
  load_config_file       = false
  host                   = var.cluster_endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

locals {
  annotations = data.kubernetes_service.ingress_gateway.metadata[0].annotations
  location    = var.cluster_type == "zonal" ? "--zone ${var.cluster_location}" : "--region ${var.cluster_location}"
  neg_name    = local.annotations != null ? jsondecode(local.annotations["cloud.google.com/neg-status"])["network_endpoint_groups"]["80"] : null
  zones       = local.annotations != null ? jsondecode(local.annotations["cloud.google.com/neg-status"])["zones"] : null
}

resource "null_resource" "wait_for_istio_ingressgateway" {
  triggers = {
    timestamp = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
    gcloud container clusters get-credentials ${var.cluster_name} ${local.location} --project ${var.project}
    while [[ $(kubectl get pods -l istio=ingressgateway -n ${var.namespace} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; \
    do echo "waiting for istio ingress gateway" && sleep 5; done
    EOT
    interpreter = ["timeout", "10m", "/bin/bash", "-c"]
  }
}

resource "null_resource" "delete_istio_ingressgateway_neg" {
  provisioner "local-exec" {
    when       = destroy
    command    = <<EOT
    neg=$(kubectl get service istio-ingressgateway -n ${var.namespace} -o jsonpath='{.metadata.annotations.cloud\.google\.com/neg-status}' | jq -r '.network_endpoint_groups["80"]')
    echo "deleting network endpoint group $neg"
    for zone in $(kubectl get service istio-ingressgateway -n ${var.namespace} -o jsonpath='{.metadata.annotations.cloud\.google\.com/neg-status}' | jq -r '.zones[]'); do
      gcloud compute network-endpoint-groups delete $neg --zone $zone --quiet
    done
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

data "google_client_config" "default" {
  depends_on = [null_resource.wait_for_istio_ingressgateway]
}

data "kubernetes_service" "ingress_gateway" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = var.namespace
  }
  depends_on = [data.google_client_config.default]
}