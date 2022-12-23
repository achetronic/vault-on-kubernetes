########################################################################################################################
## KMS
########################################################################################################################
resource "aws_kms_key" "vault" {
  description              = "AWS KMS Customer-managed key used for Vault auto-unseal and encryption"
  enable_key_rotation      = false
  is_enabled               = true
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

resource "aws_kms_alias" "vault" {
  name = "alias/vault-unsealing-key"
  target_key_id = aws_kms_key.vault.key_id
}
