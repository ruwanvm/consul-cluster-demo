####### Provider Configurations #########################
variable "aws_profile" {
  description = "AWS Profile to create resources using Terraform"
  default     = "default"
}

variable "aws_region" {
  description = "AWS region to create resources using Terraform"
}
####### Infrastructure Configurations #########################
variable "consul_vpc_id" {
  description = "id of Consul VPC created in vpc step"
}