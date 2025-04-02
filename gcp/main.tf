# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "google" {
  region = "global"
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "hcp_tf_organization" {
  type        = string
  description = "HCP Terraform Organization"
}

variable "hcp_tf_stacks_project" {
  type        = string
  description = "HCP Terraform Stacks Project"
}

# Create a service account for Terraform Stacks
resource "google_service_account" "terraform_stacks_sa" {
  account_id   = "terraform-stacks-sa"
  display_name = "Terraform Stacks Service Account"
  description  = "Service account used by Terraform Stacks for GCP resources"
}

# Enable required APIs for workload identity federation
locals {
  gcp_service_list = [
    "sts.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com"
  ]
}

resource "google_project_service" "services" {
  for_each                   = toset(local.gcp_service_list)
  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Create Workload Identity Pool (reference google_project_service to ensure APIs are enabled)
resource "google_iam_workload_identity_pool" "terraform_stacks_pool" {
  depends_on = [google_project_service.services]
  workload_identity_pool_id = "terraform-stacks-pool"
  display_name              = "Terraform Stacks Pool"
  description               = "Identity pool for Terraform Stacks authentication"
}

# Create Workload Identity Pool Provider
resource "google_iam_workload_identity_pool_provider" "terraform_stacks_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.terraform_stacks_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "terraform-stacks-provider"
  display_name                       = "Terraform Stacks Provider"
  description                        = "OIDC identity pool provider for Terraform Stacks"
  
  attribute_mapping = {
    "google.subject"                            = "assertion.sub", # WARNING - this value is has to be <=127 bytes, and is "organization:<ORG NAME>:project:<PROJ NAME>:stack:<STACK NAME>:deployment:development:operation:plan
    "attribute.aud"                             = "assertion.aud",
    "attribute.terraform_operation"             = "assertion.terraform_operation",
    "attribute.terraform_project_id"            = "assertion.terraform_project_id",
    "attribute.terraform_project_name"          = "assertion.terraform_project_name",
    "attribute.terraform_stack_id"              = "assertion.terraform_stack_id",
    "attribute.terraform_stack_name"            = "assertion.terraform_stack_name",
    "attribute.terraform_stack_deployment_name" = "assertion.terraform_stack_deployment_name",
    "attribute.terraform_organization_id"       = "assertion.terraform_organization_id",
    "attribute.terraform_organization_name"     = "assertion.terraform_organization_name",
    "attribute.terraform_run_id"                = "assertion.terraform_run_id",
  }
  oidc {
    issuer_uri = "https://app.terraform.io"
    allowed_audiences = ["hcp.workload.identity"]
  }
  attribute_condition = "assertion.sub.startsWith(\"organization:${var.hcp_tf_organization}:project:${var.hcp_tf_stacks_project}:stack\")"
}

# Switch from binding to member for service account IAM
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.terraform_stacks_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.terraform_stacks_pool.name}/*"
}

# Grant additional permissions to the service account
resource "google_project_iam_member" "sa_more_permissions" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.terraform_stacks_sa.email}"
}

# Grant editor role to the service account (similar to reference implementation)
resource "google_project_iam_member" "sa_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform_stacks_sa.email}"
}

# Outputs to be used by Terraform Stacks
output "service_account_email" {
  value       = google_service_account.terraform_stacks_sa.email
  description = "Email of the service account to be used by Terraform Stacks"
}

output "audience" {
  value       = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.terraform_stacks_provider.name}"
  description = "The audience value to use when generating OIDC tokens"
}
