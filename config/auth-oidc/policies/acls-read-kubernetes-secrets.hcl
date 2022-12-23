# Read all secrets from the new storage
path "kubernetes/data/*" {
  capabilities = ["list", "read"]
}

path "kubernetes/metadata/*" {
  capabilities = ["list", "read"]
}
