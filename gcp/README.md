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
    audience = [ <output.workload_identity_pool_provider from earlier Terraform execution> ]
}

deployment "development" {
  inputs = {
    google_project               = <the same project used in the setup>
    google_region                = <the same region used in the setup>
    google_audience              = <output.workload_identity_pool_provider from earlier Terraform execution>
    google_token_file            = identity_token.gcp.token_file
    google_service_account_email = <output.service_account_email from earlier Terraform execution>
  }  
}

```

```hcl
# main.tfstack.hcl

variable "google_project" {
    type = string
}

variable "google_region" {
    type = string
}

variable "google_audience" {
    type = string
}

variable "google_token_file" {
    type = string
}

variable "google_service_account_email" {
    type = string
}

provider "google" "this" {
  config {
    project = var.google_project
    region  = var.google_region
    credentials = jsonencode(
      {
        "type": "external_account",
        "audience": var.google_audience,
        "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
        "token_url": "https://sts.googleapis.com/v1/token",
        "credential_source": {
          "file": var.google_token_file,
         },
         "service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${var.google_service_account_email}:generateAccessToken",
      }
    )
  }
}
```
