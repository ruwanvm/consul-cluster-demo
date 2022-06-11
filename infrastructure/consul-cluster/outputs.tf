output "consul_server_autoscale_group" {
  value = aws_autoscaling_group.consul_servers_auto_scaling_group.name
}

output "consul_client_autoscale_group" {
  value = aws_autoscaling_group.consul_client_auto_scaling_group.name
}

