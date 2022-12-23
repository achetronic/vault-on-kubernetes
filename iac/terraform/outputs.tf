###############################################################
## ACCOUNT
###############################################################
output "vault_user_access_key" {
  value     = {
    id: aws_iam_access_key.vault_user_access_key.id
    secret: aws_iam_access_key.vault_user_access_key.secret
    smtp_secret: aws_iam_access_key.vault_user_access_key.ses_smtp_password_v4
  }
  sensitive = true
}

output "vault_unseal_key" {
  value     = {
    kms_id: aws_kms_key.vault.key_id
  }
  sensitive = false
}
