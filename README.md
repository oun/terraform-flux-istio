# Terraform Flux Istio

## Setup

### Generate Github Deploy Key

- Generate new SSH key
    ```
    ssh-keygen -t ed25519 -C "your_email@example.com"
    ```

- Copy private key file /Users/you/.ssh/id_ed25519 to live/dev/flux/git_private_key

- Copy contents of public key file /Users/you/.ssh/id_ed25519.pub. 
  Go to settings in your Github repo and Deploy keys, click Add deploy key button.
  Paste the public key into the key textarea and check Allow write access.