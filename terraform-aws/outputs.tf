output "aws_region" {
    value = var.aws_region
}

output "kms_key"{
    value = aws_kms_key.vault.id
}