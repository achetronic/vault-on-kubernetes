path "auth/token/create" {
  capabilities = ["create", "update", "sudo"]
}

path "auth/token/revoke" {
  capabilities = ["create", "update"]
}

path "auth/token/renew-self" {
  capabilities = ["create", "update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "sys/policies/acl/eks-*" {
  capabilities = ["read","list","create","update"]
}
