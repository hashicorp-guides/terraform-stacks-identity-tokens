# hcp

## Setup

To execute this configuration you will need to give Terraform access to the relevant HCP project.

The easiest way to do this is the automated web login flow triggered by the empty provider block.
Alternatively, you can provide relevant credentials via the `HCP_CLIENT_SECRET` and `HCP_CLIENT_ID` environment variables.

Once the Terraform configuration has been applied you should save the `workload_identity_provider` output as you will need it later.

## Terraform Stacks

You can now authenticate a HCP provider in Stacks with the following setup.

```hcl
# main.tfdeploy.hcl

identity_token "hcp" {
  audience = [ "hcp.workload.identity" ]
}

deployment "development" {
  inputs = {
    hcp_token                      = identity_token.hcp.jwt
    hcp_workload_identity_provider = <output.workload_identity_provider from earlier Terraform execution>
  }
}
```

```hcl
# main.tfstack.hcl

variable "hcp_token" {
  type      = string
  ephemeral = true
}

variable "hcp_workload_identity_provider" {
  type = string
}

provider "hcp" "this" {
  config {
    workload_identity {
      resource_name = var.hcp_workload_identity_provider
      token         = var.hcp_token
    }
  }
}
```
