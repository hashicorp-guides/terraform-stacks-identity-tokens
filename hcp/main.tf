# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "hcp" {}

data "hcp_project" "hcp_project" {
  project = var.hcp_project
}

resource "hcp_service_principal" "stacks_service_principal" {
  name   = "stacks-${var.tfc_organization}-${var.tfc_project}-${var.tfc_stack}"
  parent = data.hcp_project.hcp_project.resource_name
}

resource "hcp_project_iam_binding" "stacks_service_principal_binding" {
  project_id   = data.hcp_project.hcp_project.resource_id
  principal_id = hcp_service_principal.stacks_service_principal.resource_id

  # Set this to the level of access your stack should have.
  role = "roles/contributor"
}

locals {
  # This value decides exactly which HCP Terraform organisations, projects 
  # and stacks will have access to the chosen HCP project.
  # 
  # You can widen access here to an entire organization or project by
  # tweaking the value below. You can also restrict access to specific
  # deployments or operations. See the User Guide for more info.
  sub_regex = "^organization:${var.tfc_organization}:project:${var.tfc_project}:stack:${var.tfc_stack}:.*"
}

resource "hcp_iam_workload_identity_provider" "stacks_identity_provider" {
  name              = "stacks-${var.tfc_organization}-${var.tfc_project}-${var.tfc_stack}"
  service_principal = hcp_service_principal.stacks_service_principal.resource_name
  description       = "Allow Terraform Stacks access to this HCP Project."

  oidc = {
    issuer_uri        = "https://app.terraform.io"
    allowed_audiences = ["hcp.workload.identity"]
  }

  conditional_access = "jwt_claims.sub matches `${local.sub_regex}`"
}

output "workload_identity_provider" {
  value = hcp_iam_workload_identity_provider.stacks_identity_provider.resource_name
}
