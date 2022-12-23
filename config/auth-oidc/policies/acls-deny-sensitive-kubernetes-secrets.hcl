# Deny all secrets related to infrastructure from the new storage
path "kubernetes/data/infrastructure/*" {
  capabilities = ["deny"]
}

path "kubernetes/metadata/infrastructure/*" {
  capabilities = ["deny"]
}
