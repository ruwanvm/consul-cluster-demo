output "consul_keypair" {
  value = aws_key_pair.ec2_key.id
}

output "consul_server_security_group" {
  value = aws_security_group.consul_server_sg.id
}