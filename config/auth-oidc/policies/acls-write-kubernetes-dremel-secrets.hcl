# Write Dremel secrets from the new storage
path "kubernetes/data/dremel/*" {
  capabilities = ["create", "update", "delete"]
}

path "kubernetes/metadata/dremel/*" {
  capabilities = ["create", "update", "delete"]
}
