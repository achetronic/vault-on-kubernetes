# DISCLAIMER:
# Following acls are about restricting some access related to the default storage 'cubbyhole'
# ---

# Not allowed reading upper-managers secrets
path "cubbyhole/" {
  capabilities = ["deny"]
}

path "cubbyhole/*" {
  capabilities = ["deny"]
}
