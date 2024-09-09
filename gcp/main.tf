# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "google" {
  region  = var.google_region
  project = var.google_project
}

# First, we create a GCP service account.

resource "google_service_account" "stacks_service_account" {
  account_id   = "stacks"
  display_name = "Terraform Stacks Service Account"
}

resource "google_service_account_key" "stacks_service_account" {
  service_account_id = google_service_account.stacks_service_account.id
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

# Now, we'll upload the credentials for the service account to HCP Terraform.

provider "tfe" {}

resource "tfe_variable_set" "variables" {
  name         = "gcp-stacks"
  description  = "Credentials for accessing GCP"
  organization = var.tfc_organisation
}

resource "tfe_variable" "gcp_credentials" {
  key             = "gcp_credentials"
  value           = base64decode(google_service_account_key.stacks_service_account.private_key)
  category        = "terraform"
  description     = "Credentials for accessing GCP"
  variable_set_id = tfe_variable_set.variables.id
  sensitive       = true
}

output "varset" {
  value = tfe_variable_set.variables.id
}
