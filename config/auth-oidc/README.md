# Configure OIDC auth method on Vault

## Interaction diagram

The interaction between Keycloak and Vault is explained by the following diagram:

```text
                         ┌───────────────────┐                               ┌───────────────────────┐
                         │       Vault       │                               │        Keycloak       │
                         │                   │                               │                       │
                         │ (OIDC Configured) │                               │         (OIDC)        │
                         └──┬──────────────┬─┘                               └───────────┬───────────┘
                            │              │                                             │
                            │              │                                             │
                            │              │                                     ┌───────▼──────┐   Realm for employees
   ┌────────────────────────▼───┐ ┌────────▼───────────────────────────────┐     │   Internal   │   and internal tools
   │                            │ │                                        │     └───────┬──Realm
   │ ┌──────────┐ ┌──────────┐  │ │ ┌──────────┐ ┌──────────┐ ┌──────────┐ │             │
   │ │ Policy 1 │ │ Policy 2 │  │ │ │ Policy 1 │ │ Policy 2 │ │ Policy 3 │ │             │
   │ └──────────┘ └──────────┘  │ │ └──────────┘ └──────────┘ └──────────┘ │       ┌─────▼─────┐
   │                            │ │                                        │       │   Vault   │
   └────────────────────Group 1─┘ └──────────────────▲─────────────Group 2─┘       └─────┐Client
                                                     │                                   │
                                                     │                                   │
                                                     │                                   │
                                      ┌──────────────┴───────────────┐                ┌──▼──┐   'profile' scope
                                      │ Alias (group <> JWT 'group') │◄───────────────┤ JWT │   'groups'  claim
                                      └──────────────────────────────┘                └─────┘

                                     The alias is linking a Vault group
                                     and a defined group from 'groups'
                                     claim coming from JWT
```

## How to deploy

The first step to configure the OIDC access on Vault is defining the values for variables needed by the script that does it. 
The variables are defined as follows:

```console
# Variables for Keycloak
export KEYCLOAK_REALM_URI="https://keycloak.infrastructure.example.com/realms/internal"
export KEYCLOAK_CLIENT_ID="hashicorp-vault"
export KEYCLOAK_CLIENT_SECRET="xxxEXAMPLExxx"

# Variables for Vault itself
export VAULT_ADDR="https://vault.infrastructure.example.com"
export VAULT_ROOT_TOKEN="s.xxxEXAMPLExxx"
```

After defining the variables, you only need to execute the bast script to go, as follows:

```console
bash ./init.sh
```

> You will see some errors when resources already exists inside Vault, for example, creating aliases, etc. 
> Don't worry about it
> [and read this](README.md#why-bash-script-for-configuring-oidc-for-vault).

## FAQ

### Why Bash script for configuring OIDC for Vault?

Don't cry, baby. This decision was based on the time we had to prepare all the system. The right way is to configure Vault 
using Terraform providers, but several ways for doing this are available and SRE members had only some days to do it. 
If you have enough time to do it, please port the configuration to Terraform to get a **perfect management** of
configuration for this system.

---

#### What is a policy for Vault?

A policy is a group of permissions (ACLs) that can give (or deny) several type of permissions over a storage on Vault.
Storages are where the secrets are stored and are several of them. Vault works as a group of file systems, so the secrets
(and the configuration also) are stored on defined paths inside the storages. The access to these paths is defined by policies.

---

#### What is a group for Vault?

A group for Vault is basically a mix of policies with a name. These policies can be assigned to someone created inside
Vault (internal groups) or to someone defined externally to Vault (external groups)

---

#### What is an alias for Vault?

An alias is like a link between a group and something else. For example, in the case of the OIDC, an alias is the link
between a Vault group and the claim coming inside the JWT, for example, 'groups' commonly used by OIDC providers.
You can see this in the diagram on top of this document.

---

#### Why are aliases needed?

Aliases are needed because the concept of 'groups' for Vault is the same as the concept of 'groups' for OIDC providers,
but usually their definition is heterogeneous between those systems. Some systems like Keycloak define groups in the
same way as a path `/chapters/sre` and they are simply a word in systems like Vault `sre`. Aliases are the glue between
them.

---

#### How are the entities identified?

An entity for vault is anything that is able to sign-in.

When using openid flow, there is a concept called `scopes`. Scopes are groups of data that you ask the OIDC to give you about 
the user that is being signed-in. Some of these scopes are mandatory, for example, `openid, email, profile`, but some others
are optional. When using Keycloak as OIDC provider, `profile` scope includes the field `preferred_name` which is basically 
the username on Keycloak.

When you sign-in to Vault, using OIDC, we configured it to automatically assign you some less-permission policy, and 
some other sane defaults. Those defaults include the matching `user_claim="preferred_username"`, getting the username
from the JWT.

This way, Vault always know who is signed-in. We did this for tracing reasons.

---
