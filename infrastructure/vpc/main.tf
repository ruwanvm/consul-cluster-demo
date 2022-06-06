# Create VPC
resource "aws_vpc" "consul_cluster_vpc" {
  cidr_block                       = "10.1.0.0/16"
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name         = "Consul-Cluster"
    "Managed-by" = "Terraform"
  }
}
# Create 3 Public subnets in 3 AZ
resource "aws_subnet" "consul_cluster_public_subnet_1" {
  cidr_block              = "10.1.0.0/28"
  vpc_id                  = aws_vpc.consul_cluster_vpc.id
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name         = "Consul-Cluster-public-subnet-1"
    "Managed-by" = "Terraform"
  }
}
resource "aws_subnet" "consul_cluster_public_subnet_2" {
  cidr_block              = "10.1.0.16/28"
  vpc_id                  = aws_vpc.consul_cluster_vpc.id
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name         = "Consul-Cluster-public-subnet-2"
    "Managed-by" = "Terraform"
  }
}
resource "aws_subnet" "consul_cluster_public_subnet_3" {
  cidr_block              = "10.1.0.32/28"
  vpc_id                  = aws_vpc.consul_cluster_vpc.id
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = true
  tags = {
    Name         = "Consul-Cluster-public-subnet-3"
    "Managed-by" = "Terraform"
  }
}