# List all secrets from the new storage
path "kubernetes/data/*" {
  capabilities = ["list"]
}

path "kubernetes/metadata/*" {
  capabilities = ["list"]
}
