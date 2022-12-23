# Read Warpcache secrets from the new storage
path "kubernetes/data/warpcache/*" {
  capabilities = ["list", "read"]
}

path "kubernetes/metadata/warpcache/*" {
  capabilities = ["list", "read"]
}
