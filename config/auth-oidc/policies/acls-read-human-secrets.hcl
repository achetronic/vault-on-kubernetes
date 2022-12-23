# Permissions to be able to read from 'human' storage
# ---

path "human/*" {
  capabilities = ["list", "read"]
}
