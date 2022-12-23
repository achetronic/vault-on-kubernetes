# Vault

> The new Vault can be found [here](https://vault.infrastructure.s73cloud.com)

## Description

Hashicorp Vault deployment inside Kubernetes. This is the vault used to provision secrets across Kubernetes clusters

## Diagram

```text
        
          ┌┬─────────────┬┐       ┌┬─────────────┬┐
          ││  S3 Bucket  ││       ││   KMS key   ││
          └┴──────▲──────┴┘       └┴──────┬──────┴┘
                  │                       │
                  │ (Storage, not HA)     │ (Unsealing)
                  │                       │
          ┌───────┴───────────────────────▼───────┐
          │                                       │
          │            Hashicorp Vault            │
          │                                       │
          └──────▲───────────▲─────────▲──────────┘
                 │           │         │
                 │           │         │
                 │           │         │
                 │           │         │
          ┌──────▼─────┐     │       ┌─▼─────┐
          │ Kubernetes │     │       │ . . . │
          │  (tokens)  │     │       └───────┘
          └────────────┘     │
                             │
                        ┌────▼─────┐
                        │  Humans  │
                        │  (OIDC)  │
                        └──────────┘
```

## Motivation

In the first stages of the migration to Kubernetes, SRE members had to look for a safe way to provision secrets to the
clusters. This way had to be safe and automated too. Doing research we discovered External Secrets project, from Godaddy.
This is an operator for Kubernetes (included into the [Tooling Stack](https://gitlab.infrastructure.s73cloud.com/Infrastructure/tooling-stack)) 
which can get secrets from a vault like this, and generate Kubernetes Secrets at change. Of course, for achieving that, 
we needed a vault, and we wanted it to be agnostic to the cloud. Safe, automated, opensource, agnostic, Kubernetes friendly... 
Hashicorp Vault was basically the winner.

## Provisioning cloud resources

To launch Vault, there are several required resources. Some of them are permissions for the IAM generated user, some 
bucket to store all the data (of course, encrypted), and a KMS key that [you better not delete](README.md#unsealing-process)

These resources are created per environment, with the Terraform code inside the directory `iac/`. 
To have deeper information about the process, better read the [specific documentation](iac/README.md)


## How to deploy in Kubernetes

Once the resources are provisioned as described in the previous step, you have to put some credentials inside Kubernetes
by creating a Kubernetes Secret. This is the very first and the most important system inside infrastructure cluster which
provides credentials for the rest of clusters and systems,so this step can not be automated.

To know how to extract the credentials needed, please read [this documentation](iac/README.md#How-to-get-the-outputs)

To craft the Secret inside Kubernetes, substitute the values obtained in the following command and execute it pointing
_infrastructure_ cluster

```console
kubectl create secret generic vault-cloud-credentials -n vault \
    --from-literal AWS_ACCESS_KEY_ID=AKIAxxxEXAMPLExxx \
    --from-literal AWS_SECRET_ACCESS_KEY="xxxEXAMPLExxx" \
    --from-literal VAULT_AWSKMS_SEAL_KEY_ID=5c677541-1fc0-xxxEXAMPLExxx
```

After creating the Secret, it's time to deploy the system. You can do it by executing the following command from the root
directory of this repository:

```console
cd ./deploy
helm dependency update
helm upgrade --install vault . -f values-production.yaml --namespace vault
```

## Init your vault

> This process was done by SRE members, so you can skip this step. This information is here just to spread the knowledge
> with the rest of the teams. Moreover, you need to perform this if you launch this system inside other environments
> different to `production`

Very first time that Vault is started, some keys are required to be generated and stored in a safe place. These keys are
commonly required to unseal the vault, for that reason they are called the `Unsealing Keys`. Unsealing process can be 
automated using a KMS key as the `Unsealing Key` (spoiler: we did it).

When detecting this automation, the behaviour from Vault changes automatically, and will generate `Recovery Keys` instead
of the `Unsealing Keys`. This kind of keys are better explained in [this section](README.md#unsealing-process), so 
this documentation will focus on how to get them.

To generate the `Recovery Keys` the first time that Vault is init, just execute the following command against the 
_infrastructure_ Kubernetes cluster:

```console
kubectl exec -it -n vault pod/vault-0 -- vault operator init
```

Automatically, they will be generated, with the first `Root Token`. Please, use this token for the first provisioning and
maintenance tasks and then revoke it. You can generate others in the future as described in [this section](README.md#the-recovery-keys)
using the `Recovery Keys`. The output for the previous command is more or less like the following one:

```text
Recovery Key 1: p1njxxxEXAMPLExxx
Recovery Key 2: nDAuxxxEXAMPLExxx
Recovery Key 3: nF7jxxxEXAMPLExxx
Recovery Key 4: gi84xxxEXAMPLExxx
Recovery Key 5: Mc4hxxxEXAMPLExxx

Initial Root Token: s.xxxEXAMPLE

Success! Vault is initialized

Recovery key initialized with 5 key shares and a key threshold of 3. Please
securely distribute the key shares printed above.
```

## The recovery keys

When the automatic sealing/unsealing is configured, Vault will automatically unseal itself with a KMS key stored in the cloud.
This is suitable due to several Kubernetes clusters depends on this system, literally they get the secrets from here, so the 
less time you need to unseal, the fewer possibilities to have problems with other services, for example, the products.

Usually, when starting Vault for the first time, it generates several `Unsealing keys`, but due to ours is automatically
unsealed by configuration, then it generates `Recovery Keys`, fully delegating the unsealing process. 
These `Recovery keys` can be used together to generate a `root` token which is basically god inside Vault. Yes, I said 
together because you need at least 3 of them at the same time to generate the token. 

Of course, this special token has the highest privileges and must not be used for daily tasks, for anything, and must be 
revoked when not needed. The right way to go is generating the right policies for the real users on its place.

These `Recovery Keys` are stored in the `root` AWS account of the company, for the case the situation gets...dangerous.
So if you need to generate a root token to fight a disaster, and you are the Chapter Lead SRE, ask the upper managers for 
the access. After fixing the problem, please, revoke the token.

To generate a `Root Token` using the `Recovery Keys`, just follow the 
[official documentation](https://learn.hashicorp.com/tutorials/vault/generate-root) against the _infrastructure_ Kubernetes cluster

## Unsealing process

Commonly, the unsealing process is done manually using the `Unsealing Keys` that Vault generates when an operator (SRE member) 
inits the vault. These keys are so important due to all the data are encrypted with them inside the storage used to store
the secrets.

There is an official way to automate this process, using a single AWS KMS key as the `Unsealing Key` (encryption key), 
provided in the provisioning stage. This changes the behaviour of Vault, not generating or needing its own `Unsealing Keys`,
due to it uses that one provisioned inside the cloud provider. So everything is configured to be automatically unsealed,
and you can sleep relaxed (unless you delete the KMS key, then you are fu*@!d 😂, so better pray for yourself 🙏🏻)

## Configuration about OIDC

To be able to work with the OIDC provider (Keycloak at the moment of writing this), Vault need some configuration to
match the internal policies with the `groups` claim coming into the JWT provided by the OIDC provider. This configuration 
needs only to be applied one time (spoiler: SRE members already applied it on `production` deployment). Full documentation
for this can be found on the [specific documentation](config/auth-oidc/README.md)

## Full documentation

You have a simple set of instructions on this [README](docs/README.md) to launch the docs locally

## How to collaborate

1. Create a branch and change inside everything you need
2. Launch a cluster pointing tooling-stack to this repository but to your branch
3. Open a Pull Request to merge your code. Don't be dirty with the commits (squash them), be clear with the commit message, etc
