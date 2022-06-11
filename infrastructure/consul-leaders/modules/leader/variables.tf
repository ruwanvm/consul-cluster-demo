variable "subnet_id" {
  description = "consul public subnet ID"
}
variable "consul_ami_id" {
  description = "Consul AMI ID"
}
variable "keypair_id" {
  description = "AWS SSH keypair id"
}
variable "security_group" {
  description = "AWS Security group to attach"
}
variable "iam_instance_profile" {
  description = "Instance Profile with AWS IAM role to attach on Master AMI instance"
}
variable "private_ip" {
  default = "Private IP of the instance"
}
variable "name_tag" {
  default = "Name of the leader instance"
}