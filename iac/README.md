# IaC for Vault

## Description
Some infrastructure resources are needed by Vault in order to work. This is the code to create them.

## Motivation
As you can see in the following lines, you must execute a bash script as a wrapper of Terraform execution. 
This is convenient because in this company, we store the `tfstate` files in different buckets according to the environment
and Terraform does not allow to parametrize the `backend` block of the provider. This script basically does so.

> Why not to use Terragrunt, which is designed for exactly these situations? 
> dude, Bash is everywhere and this is simply a script

## How to perform
To create the resources on the cloud provider, just execute the following command:

```console
bash scripts/operate.sh -f develop.tfvars -o apply
```

If you need to destroy the resources, just execute the following command:

```console
bash scripts/operate.sh -f develop.tfvars -o destroy
```

# How to get the outputs

Once applied has been performed with the script, you have your backend already configured. Because of that, you can get 
the outputs executing the following, for example, to get the `vault_user_access_key` and the `vault_unseal_key`

```console
cd terraform && terraform output vault_user_access_key && terraform output vault_unseal_key
```

## Permissions

As always, permissions are needed to be able to create resources on cloud providers. So most times, only the SREs can
execute this code. Contact them??
