output "consul_ami_id" {
  value = aws_ami_from_instance.consul_ami.id
}