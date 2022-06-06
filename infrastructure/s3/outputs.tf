output "consul_config_bucket" {
  value = aws_s3_bucket.consul_configs_bucket.bucket
}