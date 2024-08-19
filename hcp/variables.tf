# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "hcp_project" {
  type = string

  # Leave this null to select your default HCP project.
  nullable = true
  default  = null
}

variable "tfc_organization" {
  type = string
}

variable "tfc_project" {
  type = string
}

variable "tfc_stack" {
  type = string
}