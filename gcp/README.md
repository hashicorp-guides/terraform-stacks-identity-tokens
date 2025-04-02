# gcp

## Setup

To execute this configuration you will need to give Terraform access to the relevant GCP project.

More information on configuration here is available from the [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication).

Once the Terraform configuration has been applied you should save the `workload_identity_pool_provider` and `service_account_email` outputs as you will need them later.

## Terraform Stacks

You can now authenticate a GCP provider in Stacks with the following setup:

```hcl
# main.tfdeploy.hcl

identity_token "gcp" {
  audience = ["hcp.workload.identity"]
}

deployment "staging" {
  inputs = {
    jwt = identity_token.gcp.jwt
  }
}

```

```hcl
# main.tfstack.hcl

provider "google" "this" {
  config {
    external_credentials {
      audience = output.audience // audience from WIF
      service_account_email = output.service_account_email // service account created from WIF
      identity_token = var.jwt
    }
  }
}

variable "jwt" {
  type = string
}

component "storage_buckets" {
    source = "./buckets"

    inputs = {
        jwt = var.jwt
    }

    providers = {
        google    = provider.google.this
    }
}
```
