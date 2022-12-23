# Read Dremel secrets from the new storage
path "kubernetes/data/dremel/*" {
  capabilities = ["list", "read"]
}

path "kubernetes/metadata/dremel/*" {
  capabilities = ["list", "read"]
}
