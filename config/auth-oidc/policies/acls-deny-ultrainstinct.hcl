# DISCLAIMER:
# Following acls are about restricting some access related to the storage for upper-managers
# ---

# Not allowed reading upper-managers secrets
path "ultrainstinct/" {
  capabilities = ["deny"]
}

path "ultrainstinct/*" {
  capabilities = ["deny"]
}
