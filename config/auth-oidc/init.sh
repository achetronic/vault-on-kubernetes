#!/usr/bin/env bash

########################################################################################################################
# DISCLAIMER:
# This script is not finished. It is useful to bootstrap things needed by the OIDC auth method to work (policies, auth,
# groups, aliases...)
# This task can be done using Terraform, due to the existence an official provider, but was done using Bash for speed
########################################################################################################################

# Variables for Keycloak
export KEYCLOAK_REALM_URI="https://keycloak.infrastructure.s73cloud.com/realms/internal"
export KEYCLOAK_CLIENT_ID="hashicorp-vault"
export KEYCLOAK_CLIENT_SECRET="xxxEXAMPLExxx"

# Variables for Vault itself
export VAULT_ADDR="https://vault.infrastructure.s73cloud.com"
export VAULT_ROOT_TOKEN="s.xxxEXAMPLExxx"

########################################################################################################################
# Login into Vault
vault login "${VAULT_ROOT_TOKEN}"

# Enable the OIDC auth method
vault auth enable oidc

# Configure OIDC auth method
vault write auth/oidc/config \
      oidc_discovery_url="$KEYCLOAK_REALM_URI" \
      oidc_client_id="$KEYCLOAK_CLIENT_ID" \
      oidc_client_secret="$KEYCLOAK_CLIENT_SECRET" \
      default_role="oidc_default_role"

# Get the ID of the OIDC auth method
VAULT_OIDC_AUTH_ACCESSOR=$(vault auth list -format=json  | jq -r '."oidc/".accessor')

# Create the default OIDC role to attach policies later, using groups
vault write auth/oidc/role/oidc_default_role \
      bound_audiences="$KEYCLOAK_CLIENT_ID" \
      allowed_redirect_uris="${VAULT_ADDR}/ui/vault/auth/oidc/oidc/callback" \
      allowed_redirect_uris="http://localhost:8250/oidc/callback" \
      oidc_scopes="openid,email,profile,groups" \
      user_claim="preferred_username" \
      groups_claim="groups" \
      policies="default" \
      verbose_oidc_logging="true"

# Get available groups
GROUPS_LIST=$(ls groups)

# Loop over the groups configuring them
for GROUP_NAME in $GROUPS_LIST; do

  PARSED_GROUP_NAME=$(echo "${GROUP_NAME}" | cut -d "." -f 1)

  # Get the policies for the current group
  POLICIES=$(jq -M -r '.policies | join(" ")' < "groups/$GROUP_NAME")

  # Parse all the policies in a single line string for Bash
  POLICIES_CMD=""
  for POLICY in $POLICIES; do
    POLICIES_CMD+=" policies=${POLICY}"
  done

  # Actually write the policies into the group
  VAULT_WRITE_GROUP_CMD="vault write identity/group name=${PARSED_GROUP_NAME} type=external ${POLICIES_CMD}"
  eval "${VAULT_WRITE_GROUP_CMD}"

  # Get the ID of the group recently created
  VAULT_GROUP_ID=$(vault read -field=id identity/group/name/"${PARSED_GROUP_NAME}")

  # Set the alias to match claim 'groups' from OIDC and Vault groups
  VAULT_GROUP_ALIAS=$(jq -M -r '.alias.name' < "groups/$GROUP_NAME")

  vault write identity/group-alias name="${VAULT_GROUP_ALIAS}" \
        mount_accessor="${VAULT_OIDC_AUTH_ACCESSOR}" \
        canonical_id="${VAULT_GROUP_ID}"
done

# Get available policies
POLICIES_LIST=$(ls policies)

# Loop over the policies configuring them
for POLICY_NAME in $POLICIES_LIST; do
  PARSED_POLICY_NAME=$(echo "${POLICY_NAME}" | cut -d "." -f 1)
  vault policy write "${PARSED_POLICY_NAME}" ./policies/"${POLICY_NAME}"
done
