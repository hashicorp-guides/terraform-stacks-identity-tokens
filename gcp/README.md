# gcp

## Setup

To execute this configuration you will need to give Terraform access to the relevant GCP project.

More information on configuration here is available from the [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication).

Once the Terraform configuration has been applied you should save the `varset` output as you will need them later.

## Terraform Stacks

You can now authenticate a GCP provider in Stacks with the following setup:

```hcl
# main.tfdeploy.hcl

store "varset" "credentials" {
  id       = <output.varset from earlier Terraform execution>
  category = "terraform"  
}

deployment "development" {
  inputs = {
    google_project               = <the same project used in the setup>
    google_region                = <the same region used in the setup>
    google_credentials           = store.varset.credentials.gcp_credentials
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

variable "google_credentials" {
  type      = string
  ephemeral = true  
}

provider "google" "this" {
  config {
    project     = var.google_project
    region      = var.google_region
    credentials = var.google_credentials
  }
}
```
