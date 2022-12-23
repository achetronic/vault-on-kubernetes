# Write Warpcache secrets from the new storage
path "kubernetes/data/warpcache/*" {
  capabilities = ["create", "update", "delete"]
}

path "kubernetes/metadata/warpcache/*" {
  capabilities = ["create", "update", "delete"]
}
