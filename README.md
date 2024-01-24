# Vault AWS KMS Auto-Unseal Demo

When initiating a Vault server, it begins in a sealed state, unable to decrypt data. The process of unsealing, constructing the master key required for decryption, is essential before performing any operations. This guide illustrates how Terraform can be utilized to provision a Vault server, employing an encryption key from AWS Key Management Services (KMS) for automatic unsealing.

The traditional Vault unseal operation demands a quorum of existing unseal keys, distributed using Shamir's Secret Sharing algorithm, preventing the concentration of critical keys in one person's possession. However, manual unsealing becomes cumbersome with multiple Vault clusters, each having distinct key holders and keys.

Vault supports automatic unsealing through various cloud technologies such as AliCloud KMS, AWS KMS, Azure Key Vault, Google Cloud KMS, and OCI KMS. This feature allows operators to delegate the unsealing process to trusted cloud providers, facilitating operations during partial failures and aiding in the creation of new or ephemeral clusters.

## Auto Unseal

Auto Unseal alleviates the operational complexity of securing unseal keys by delegating this responsibility to a trusted device or service. During startup, Vault connects to the designated device or service, requesting decryption of the root key retrieved from storage.

Certain Vault operations, beyond unsealing, necessitate a quorum of users, like generating a root token. With a Shamir seal, unseal keys authorize these operations, while Auto Unseal requires recovery keys. Just as initializing with a Shamir seal produces unseal keys, initializing with Auto Unseal yields recovery keys.

While it is possible to seal a Vault node using the API, Vault remains sealed until restarted or the unseal API is utilized. With Auto Unseal, this process requires recovery key fragments instead of unseal key fragments provided by Shamir. The overall process remains the same.

## Related Guides
* [AWS KMS Seal](https://developer.hashicorp.com/vault/docs/configuration/seal/awskms#key-rotation)
* [Auto-unseal using AWS KMS](https://developer.hashicorp.com/vault/tutorials/auto-unseal/autounseal-aws-kms)
* [Seal/Unseal](https://developer.hashicorp.com/vault/docs/concepts/seal)

## Prerequisites
* AWS account for provisioning cloud resources
* Terraform installed with basic understanding of its usage

> **_NOTE:_** Seal migration from Auto Unseal to Auto Unseal of the same type is supported since Vault 1.6.0. However, migrating from AWS KMS to AWS KMS has a limitation; all other seal migrations of the same type are supported. Seal migration from one Auto Unseal type (AWS KMS) to another (HSM, Azure KMS, etc.) is supported on older versions as well.

## Step 1: Provision Cloud Resources

```bash
cd terraform-aws

export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"

terraform init
terraform apply

cd ..
```

## Step 2: Configure Vault
Set an environment variable called `VAULT_AWSKMS_SEAL_KEY_ID` with the output `kms_key`.

```bash
export VAULT_AWSKMS_SEAL_KEY_ID=""
```

## Step 3: Run Vault
```bash
vault server -config=./vault/vault.hcl
```

## Step 4: Initialize Vault
Perform this step in another terminal tab.

> **_NOTE:_** Initialization generates Recovery Keys (instead of unseal keys) with auto-unseal. Some Vault operations still require Shamir keys. For instance, to regenerate a root token, each key holder must enter their recovery key. Like unseal keys, you can specify the number of recovery keys and the threshold using the `-recovery-shares` and `-recovery-threshold` flags. Initializing Vault with PGP is strongly recommended.

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault status

vault operator init
```