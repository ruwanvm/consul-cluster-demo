output "leader_ip" {
  value = aws_eip.consul_leader_eip.public_ip
}