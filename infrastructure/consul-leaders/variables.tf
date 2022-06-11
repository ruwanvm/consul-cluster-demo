variable "aws_profile" {
  description = "AWS Profile to create resources using Terraform"
  default     = "default"
}
variable "aws_region" {
  description = "AWS region to create resources using Terraform"
}
####### Infrastructure Configurations #########################
variable "consul_ami_id" {
  description = "Consul AMI ID"
}
variable "security_group" {
  description = "AWS Security group to attach on Consul launch configurations"
}
variable "iam_instance_profile" {
  description = "Instance Profile with AWS IAM role to attach on Consul launch configurations"
}
variable "keypair_id" {
  description = "AWS SSH keypair id"
}
variable "subnet_id_1" {
  description = "consul public subnet 1a"
}
variable "subnet_id_2" {
  description = "consul public subnet 1b"
}
variable "subnet_id_3" {
  description = "consul public subnet 1c"
}
variable "leader_public_ip" {
  description = "static ip for leader network primary"
}