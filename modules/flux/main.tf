terraform {
  backend "gcs" {}
  required_version = "= 0.12.26"

  required_providers {
    google     = "= 3.25.0"
  }
}
# ------------------------------------------------------------------------------
# DEPLOY FLUX
# ------------------------------------------------------------------------------

provider "kubernetes" {
  load_config_file       = false
  host                   = var.cluster_endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

provider "kubectl" {
  load_config_file       = false
  host                   = var.cluster_endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    load_config_file       = false
    host                   = var.cluster_endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  }
}

data "google_client_config" "default" {
}

resource "kubernetes_namespace" "flux_namespace" {
  metadata {
    name = var.flux_namespace
  }
}

resource "kubernetes_secret" "git_secret" {
  metadata {
    name      = "flux-git-deploy"
    namespace = var.flux_namespace
  }
  data = {
    "identity" = "${file("${path.module}/${var.flux_git_private_key}")}"
  }
  depends_on = [kubernetes_namespace.flux_namespace]
}

resource "helm_release" "fluxcd" {
  chart      = "flux"
  repository = "https://charts.fluxcd.io"
  name       = "flux"
  namespace  = var.flux_namespace
  wait       = true
  set {
    name = "git.url"
    value = var.flux_git_repo
  }
  set {
    name = "git.branch"
    value = var.flux_git_branch
  }
  set {
    name = "git.path"
    value = join("\\,", var.flux_git_path)
  }
  set {
    name = "git.secretName"
    value = "flux-git-deploy"
  }
  set {
    name = "git.pollInterval"
    value = var.flux_git_poll_interval
  }
  set {
    name = "registry.automationInterval"
    value = var.flux_registry_poll_interval
  }
  set {
    name = "registry.rps"
    value = var.flux_registry_rps
  }
  set {
    name = "sync.state"
    value = "secret"
  }
  set {
    name = "syncGarbageCollection.enabled"
    value = "true"
  }
  set {
    name = "manifestGeneration"
    value = "true"
  }
  set {
    name = "resources.requests.cpu"
    value = "500m"
  }
  set {
    name = "resources.requests.memory"
    value = "256Mi"
  }
  set {
    name = "resources.limits.cpu"
    value = "1"
  }
  set {
    name = "resources.limits.memory"
    value = "512Mi"
  }
  values = [
    yamlencode({
      "additionalArgs": [
        "--connect=ws://fluxcloud"
      ]
    })
  ]
  depends_on = [kubernetes_secret.git_secret]
}

resource "kubectl_manifest" "helm_operator_crds" {
  provider = kubectl

  yaml_body = file("./manifests/crds.yaml")
  depends_on = [helm_release.fluxcd]
}

resource "helm_release" "helm_operator" {
  chart      = "helm-operator"
  repository = "https://charts.fluxcd.io"
  name       = "helm-operator"
  namespace  = var.flux_namespace
  wait       = true
  set {
    name = "git.ssh.secretName"
    value = "flux-git-deploy"
  }
  set {
    name = "helm.versions"
    value = "v3"
  }
  set {
    name = "initPlugins.enable"
    value = true
  }
  set {
    name = "initPlugins.cacheVolumeName"
    value = "helm-plugins-cache"
  }
  set {
    name = "initPlugins.plugins[0].helmVersion"
    value = "v3"
  }
  set {
    name = "initPlugins.plugins[0].plugin"
    value = "https://github.com/hayorov/helm-gcs.git"
  }
  set {
    name = "initPlugins.plugins[0].version"
    value = "0.3.5"
  }
  set {
    name = "resources.requests.cpu"
    value = "500m"
  }
  set {
    name = "resources.requests.memory"
    value = "256Mi"
  }
  set {
    name = "resources.limits.cpu"
    value = "1"
  }
  set {
    name = "resources.limits.memory"
    value = "512Mi"
  }
  depends_on = [kubectl_manifest.helm_operator_crds]
}
