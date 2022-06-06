output "consul_vpc_id" {
  value = aws_vpc.consul_cluster_vpc.id
}
output "consul_subnet_1_id" {
  value = aws_subnet.consul_cluster_public_subnet_1.id
}
output "consul_subnet_2_id" {
  value = aws_subnet.consul_cluster_public_subnet_2.id
}
output "consul_subnet_3_id" {
  value = aws_subnet.consul_cluster_public_subnet_3.id
}