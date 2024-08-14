# azure

This directory contains the terraform code to create an Azure Service Principal and the Federated Identity credentials which will be used in later Terraform Stacks operations.

## Setup

To execute this configuration you will need to give Terraform access to the relevant Azure account. Refer the [following](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure) terraform provider docs to authenticate with Azure.

Once the Terraform configuration has been applied you should save the following from your terraform output:

1. `tenant_id` of the Azure AD/Microsoft Entra ID service.
2. `client_id` of the registered application created by this terraform setup.
3. `subscription_id` of your Azure account.

**Warning**
The `Contributor` role assignment is just used as an example. This is not recommended for production workloads.

## Terraform Stacks

Once the above setup is complete, we can go ahead and proceed with running Terraform Stack operations.

```hcl
identity_token "azurerm" {
  audience = ["api://AzureADTokenExchange"]
}

deployment "production" {
  inputs = {
    identity_token = identity_token.azurerm.jwt

    client_id       = "<Client ID from the setup>"
    subscription_id = "<Subscription ID from the setup>"
    tenant_id       = "<Tenant ID from the setup>"
  }
}
```

For more details, please refer our Azure stacks example [guide](https://github.com/hashicorp-guides/azure-stacks-example).
