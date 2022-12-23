# Write Polynet secrets from the new storage
path "kubernetes/data/polynet/*" {
  capabilities = ["create", "update", "delete"]
}

path "kubernetes/metadata/polynet/*" {
  capabilities = ["create", "update", "delete"]
}
