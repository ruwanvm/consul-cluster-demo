####### Provider Configurations #########################
variable "aws_profile" {
  description = "AWS Profile to create resources using Terraform"
  default     = "default"
}

variable "aws_region" {
  description = "AWS region to create resources using Terraform"
}
####### Infrastructure Configurations #########################
variable "consul_bucket" {
  description = "Consul configurations bucket"
}
variable "consul_ami_id" {
  description = "AMI ID of the consul installation"
}
variable "instance_type" {
  description = "Instance Type for Master AMI instance"
  default     = "t2.micro"
}
variable "keypair_id" {
  description = "AWS SSH keypair id"
}
variable "security_group" {
  description = "AWS Security group to attach on Master AMI instance"
}
variable "subnet_id" {
  description = "AWS Subnet ID to launch Master AMI instance"
}
variable "iam_instance_profile" {
  description = "Instance Profile with AWS IAM role to attach on Master AMI instance"
}