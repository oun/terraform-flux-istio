# Terraform Flux Istio

GitOps using TerraGrunt and Terraform to provision Google Kubernetes Engine cluster and deploy Fluxcd and Istio.

## Prerequisites

- Google Cloud Project
- TerraGrunt and Terraform
- Kubectl Terraform provider

### Project Structure

- `gitops` contains deployment manifest files e.g. kustomize, helm, k8s manifests.
   - app example bookinfo service deployment manifests
   - istio manifests for deploying Itio and operator
- `live` contains Terragrunt and Terraform configurations for each environment.
   - demo example environment contains module inputs
- `modules` contains reusable Terraform modules.
   - flux module for FluxCD and Helm operator
   - gke module to provision Kubernetes Engine
   - http-lb module for HTTP Load Balancer
   - istio-neg module for Istio Ingress Gateway NEG

In the real world, you should have separated git repositories.

## Setup

### Service Account and IAM

- Create a Service Account and assign following roles:
  - Storage Admin
  - Kubernetes Engine Admin
  - Compute Admin
  - Service Account User
- Create and download Service Account JSON key
- Set google application credentials to the JSON key
    ```
    export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
    ```

### Generate Github Deploy Key

- Generate new SSH key
    ```
    ssh-keygen -t ed25519 -C "your_email@example.com"
    ```

- Copy private key file /Users/you/.ssh/id_ed25519 to live/demo/flux/git_private_key

- Copy contents of public key file /Users/you/.ssh/id_ed25519.pub. 
  Go to settings in your Github repo and Deploy keys, click Add deploy key button.
  Paste the public key into the key textarea and check Allow write access.
 
### Update Terraform Inputs

- Change `project` and `region` in live/demo/env.hcl to your gcp project and region
- Change `flux_git_repo` in live/demo/flux/terragrunt.hcl to your git repository

## Usage

Change directory to `live/demo`
```
terragrunt apply-all
```

This scripts will do:
- Create and keep terraform remote state in a GCS bucket.
- Provision zonal GKE cluster v1.16.x with preemptible node pool.
- Deploy FluxCD and Helm operator to flux namespace.
- FluxCD sync deployments from gitops directory then deploy Istio Operator and bookinfo application.
- Istio Operator install the Istiod and Istio Ingress gateway.
- The istio-neg module waiting for Istio Ingress gateway to be ready and then get its NEG name.
- Provision HTTP Load Balancer, forwarding rule and NEG backend for Istio Ingress gateway.
- Provision firewall rule for health checking NEG backend.

When Terraform execution finish, it will output ip address of the HTTP Load Balancer.

Go to the sample bookinfo URL:
http://your-load-balancer-ip/productpage

## Clean up

To destroy all provisioned resources:
```
terragrunt destroy-all
```

## Reference:

https://github.com/stefanprodan/gitops-istio
