# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "google" {
  region  = var.google_region
  project = var.google_project
}

resource "google_iam_workload_identity_pool" "stacks_identity_pool" {
  workload_identity_pool_id = "stacks-${var.tfc_organization}-${var.tfc_project}-${var.tfc_stack}"
}

locals {
  # This value decides exactly which HCP Terraform organisations, projects 
  # and stacks will have access to the chosen GCP project.
  # 
  # You can widen access here to an entire organization or project by
  # tweaking the value below. You can also restrict access to specific
  # deployments or operations. See the User Guide for more info.
  sub_starts_with = "organization:${var.tfc_organization}:project:${var.tfc_project}:stack:${var.tfc_stack}"
}

resource "google_iam_workload_identity_pool_provider" "stacks_identity_pool_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.stacks_identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "stacks-${var.tfc_organization}-${var.tfc_project}-${var.tfc_stack}"
  attribute_mapping = {
    "google.subject"                            = "assertion.sub",
    "attribute.aud"                             = "type(assertion.aud) == list ? assertion.aud[0] : assertion.aud",
    "attribute.terraform_operation"             = "assertion.terraform_operation",
    "attribute.terraform_stack_deployment_name" = "assertion.terraform_stack_deployment_name",
    "attribute.terraform_stack_id"              = "assertion.terraform_stack_id",
    "attribute.terraform_stack_name"            = "assertion.terraform_stack_name",
    "attribute.terraform_project_id"            = "assertion.terraform_project_id",
    "attribute.terraform_project_name"          = "assertion.terraform_project_name",
    "attribute.terraform_organization_id"       = "assertion.terraform_organization_id",
    "attribute.terraform_organization_name"     = "assertion.terraform_organization_name",
    "attribute.terraform_plan_id"               = "assertion.terraform_plan_id"
  }
  oidc {
    issuer_uri = "https://app.terraform.io"
  }

  // only my organisation can access, and only from the stacks project
  attribute_condition = "assertion.sub.startsWith(\"${local.sub_starts_with}\")"
}

resource "google_service_account" "stacks_service_account" {
  account_id   = "stacks-${var.tfc_organization}-${var.tfc_project}-${var.tfc_stack}"
  display_name = "Terraform Stacks Service Account"
}

resource "google_service_account_iam_member" "stacks_service_account_membership" {
  service_account_id = google_service_account.stacks_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfc.name}/*"
}


# Now, we're going to give the new service account access to things we're going to be managing in our stack.
#
# The policies being attached here are way to broad for a regular use case, but they make sure
# my stacks can do anything during development and testing. In practice you should give the
# stack access only to what it needs to manage.

resource "google_project_iam_member" "stacks_service_account_membership" {
  project = var.google_project
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.stacks_service_account.email}"
}

output "workload_identity_pool_provider" {
  value = google_iam_workload_identity_pool_provider.stacks_identity_pool_provider.id
}

output "service_account_email" {
  value = google_service_account.stacks_service_account.email
}