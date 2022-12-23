
locals {
  # Produce a list with all the ARNs of the buckets
  # ready to be attached to the 'Resource' list of a policy
  bucket_arn_list = flatten(concat([
    for bucket in aws_s3_bucket.buckets :
    tolist([bucket.arn, "${bucket.arn}/*"])
  ]))
}

########################################################################################################################
## USERS
########################################################################################################################
resource "aws_iam_user" "vault_user" {
  name = var.iam_user
}

resource "aws_iam_access_key" "vault_user_access_key" {
  user   = aws_iam_user.vault_user.name
  status = "Active"
}

########################################################################################################################
## POLICIES
########################################################################################################################
# Policy to grant full access only to AWS resources created by this Terraform code
data "aws_iam_policy_document" "vault_policy_document" {

  version = "2012-10-17"

  # Policies for S3 buckets
  statement {
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]
    effect    = "Allow"
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    actions = [
      "s3:*"
    ]
    effect    = "Allow"
    resources = local.bucket_arn_list
  }

  # Policies for accessing KMS services
  statement {
    actions = [
      "kms:*"
    ]
    effect = "Allow"
    resources = [aws_kms_key.vault.arn]
  }
}

resource "aws_iam_policy" "vault_policy" {
  name = "VaultOwnedResourcesAccess"

  policy = data.aws_iam_policy_document.vault_policy_document.json
}

########################################################################################################################
## POLICY ATTACHMENTS
########################################################################################################################

# Attachment between the user and the policies
resource "aws_iam_user_policy_attachment" "vault_policy_attachment" {
  user       = aws_iam_user.vault_user.name
  policy_arn = aws_iam_policy.vault_policy.arn
}
