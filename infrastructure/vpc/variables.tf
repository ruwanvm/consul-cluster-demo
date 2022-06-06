####### Provider Configurations #########################
variable "aws_profile" {
  description = "AWS Profile to create resources using Terraform"
  default     = "default"
}
variable "aws_region" {
  description = "AWS region to create resources using Terraform"
}