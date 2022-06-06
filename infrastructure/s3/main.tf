resource "aws_s3_bucket" "consul_configs_bucket" {
  bucket = var.consul_config_s3_bucket
  tags = {
    "Name"       = var.consul_config_s3_bucket
    "Managed-by" = "Terraform"
  }
}