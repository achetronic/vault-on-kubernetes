# Read Polynet secrets from the new storage
path "kubernetes/data/polynet/*" {
  capabilities = ["list", "read"]
}

path "kubernetes/metadata/polynet/*" {
  capabilities = ["list", "read"]
}
