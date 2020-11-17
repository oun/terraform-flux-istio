# Terraform Flux Istio

GitOps using TerraGrunt and Terraform to provision Google Kubernetes Engine cluster and deploy Fluxcd and Istio.

## Prerequisites
- Google Cloud Project
- TerraGrunt and Terraform

## Setup

### Generate Github Deploy Key

- Generate new SSH key
    ```
    ssh-keygen -t ed25519 -C "your_email@example.com"
    ```

- Copy private key file /Users/you/.ssh/id_ed25519 to live/demo/flux/git_private_key

- Copy contents of public key file /Users/you/.ssh/id_ed25519.pub. 
  Go to settings in your Github repo and Deploy keys, click Add deploy key button.
  Paste the public key into the key textarea and check Allow write access.
  
### Update GCP Project

- Update `project` and `region` in live/demo/env.hcl to your gcp project and region
- Update `backend_project` in live/terragrunt.hcl to your gcp project


## Usage

Change directory to `live/demo`
```
terragrunt apply-all
```

This scripts will do:
- Provision zonal GKE cluster v1.16.x with preemptible node pool.
- Deploy FluxCD and Helm operator to flux namespace.
- FluxCD sync deployments from gitops directory then deploy Istio Operator and bookinfo application.
- Istio Operator install the Istiod and Istio Ingress gateway.
- The istio-neg module waiting for Istio Ingress gateway to be ready and then get the NEG name.
- Provision HTTP Load Balancer, forwarding rule and NEG backend of Istio Ingress gateway.
- Provision firewall rule for health check NEG backend.

When Terraform execution finish, it will output ip address of the HTTP Load Balancer.

Go to the sample bookinfo URL:
http://your-load-balancer-ip/productpage

Reference:

https://github.com/stefanprodan/gitops-istio
