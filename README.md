# Vault AWS KMS Auto-Unseal Demo
When a Vault server is started, it starts in a sealed state and it does not know how to decrypt data. Before any operation can be performed on the Vault, it must be unsealed. Unsealing is the process of constructing the master key necessary to decrypt the data encryption key. This guide demonstrates an example and demo of how to use Terraform to provision a Vault server that can use an encryption key from AWS Key Management Services (KMS) to automatically unseal.

Vault unseal operation requires a quorum of existing unseal keys split by Shamir's Secret sharing algorithm. This is done so that the "keys to the kingdom" won't fall into one person's hand. However, this process is manual and can become painful when you have many Vault clusters as there are now many different key holders with many different keys.

Vault supports opt-in automatic unsealing via cloud technologies: AliCloud KMS, AWS KMS, Azure Key Vault, Google Cloud KMS, and OCI KMS. This feature enables operators to delegate the unsealing process to trusted cloud providers to ease operations in the event of partial failure and to aid in the creation of new or ephemeral clusters.

## Auto Unseal
Auto Unseal was developed to aid in reducing the operational complexity of keeping the unseal key secure. This feature delegates the responsibility of securing the unseal key from users to a trusted device or service. At startup Vault will connect to the device or service implementing the seal and ask it to decrypt the root key Vault read from storage.

There are certain operations in Vault besides unsealing that require a quorum of users to perform, e.g. generating a root token. When using a Shamir seal the unseal keys must be provided to authorize these operations. When using Auto Unseal these operations require recovery keys instead.

Just as the initialization process with a Shamir seal yields unseal keys, initializing with an Auto Unseal yields recovery keys.

It is still possible to seal a Vault node using the API. In this case Vault will remain sealed until restarted, or the unseal API is used, which with Auto Unseal requires the recovery key fragments instead of the unseal key fragments that would be provided with Shamir. The process remains the same.

## Related Guides
* [AWS KMS Seal ](https://developer.hashicorp.com/vault/docs/configuration/seal/awskms#key-rotation)
* [Auto-unseal using AWS KMS](https://developer.hashicorp.com/vault/tutorials/auto-unseal/autounseal-aws-kms)

## Prerequisites
* AWS account for provisioning cloud resources
* Terraform installed and basic understanding of its usage

> **_NOTE:_** Seal migration from Auto Unseal to Auto Unseal of the same type is supported since Vault 1.6.0. However, there is a current limitation that prevents migrating from AWS KMS to AWS KMS; all other seal migrations of the same type are supported. Seal migration from one Auto Unseal type (AWS KMS) to another Auto Unseal type (HSM, Azure KMS, etc.) is also supported on older versions as well.

## Step 1: Provision the cloud resources

```bash
cd terraform-aws

export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"

terraform init
terraform apply

cd ..
```

## Step 2: Configure Vault
Set an envrioment var called `VAULT_AWSKMS_SEAL_KEY_ID` with the output `kms_key`
```bash
export VAULT_AWSKMS_SEAL_KEY_ID=""
```

## Step 3: Run vault
```bash
vault server -config=./vault/vault.hcl
```

## Step 4: Initialize Vault
Do this in another tab. 

> **_NOTE:_** The initialization generates Recovery Keys (instead of unseal keys) when using auto-unseal. Some of the Vault operations still require Shamir keys. For example, to regenerate a root token, each key holder must enter their recovery key. Similar to unseal keys, you can specify the number of recovery keys and the threshold using the -recovery-shares and -recovery-threshold flags. It is strongly recommended to initialize Vault with PGP.

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault status

vault operator init
```