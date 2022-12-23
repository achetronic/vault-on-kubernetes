# Permissions to be able to write inside 'human' storage.
# Both needed: data, metadata
# ---

path "human/data/*" {
  capabilities = ["create", "update", "delete"]
}

path "human/metadata/*" {
  capabilities = ["create", "update", "delete"]
}
