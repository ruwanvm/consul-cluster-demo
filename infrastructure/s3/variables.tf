####### Provider Configurations #######################################
variable "aws_profile" {
  description = "AWS Profile to create resources using Terraform"
  default     = "default"
}
variable "aws_region" {
  description = "AWS region to create resources using Terraform"
}

####### Infrastructure Configurations #################################
variable "consul_config_s3_bucket" {
  description = "AWS S3 bucket name to get/put Consul configs"
}