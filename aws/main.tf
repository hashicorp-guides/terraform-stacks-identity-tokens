# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.aws_region
}

resource "aws_iam_openid_connect_provider" "stacks_openid_provider" {
  url            = "https://app.terraform.io"
  client_id_list = ["aws.workload.identity"]

  # You can verify the thumbprint separately, but this is the correct
  # thumbprint for https://app.terraform.io as of 2024/08/07.
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}

resource "aws_iam_role" "stacks_role" {
  name               = "stacks-${var.tfc_organization}-${var.tfc_project}-${var.tfc_stack}"
  assume_role_policy = data.aws_iam_policy_document.stacks_role_policy.json
}

data "aws_iam_policy_document" "stacks_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.stacks_openid_provider.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "app.terraform.io:aud"
      values   = ["aws.workload.identity"]
    }
    condition {
      test     = "StringLike"
      variable = "app.terraform.io:sub"
      # This value decides exactly which HCP Terraform organisations, projects 
      # and stacks will be able to assume the new role.
      # 
      # You can widen access here to an entire organization or project by
      # tweaking the value below. You can also restrict access to specific
      # deployments or operations. See the User Guide for more info.
      values = ["organization:${var.tfc_organization}:project:${var.tfc_project}:stack:${var.tfc_stack}:*"]
    }
  }
}

# Now, we're going to give the new role access to things we're going to be managing in our stack.
#
# The policies being attached here are way to broad for a regular use case, but they make sure
# my stacks can do anything during development and testing. In practice you should give the
# stack access only to what it needs to manage.

resource "aws_iam_role_policy_attachment" "iam" {
    role = aws_iam_role.stacks_role.name
    policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "sudo" {
    role = aws_iam_role.stacks_role.name
    policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

output "role_arn" {
    value = aws_iam_role.stacks_role.arn
}
