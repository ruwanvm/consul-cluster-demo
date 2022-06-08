# Create VPC
resource "aws_vpc" "consul_cluster_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
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

# Internet Gateway and Route Tables
resource "aws_internet_gateway" "consul_internet_gateway" {
  vpc_id = aws_vpc.consul_cluster_vpc.id
  tags = {
    Name         = "Consul-Cluster-igw"
    "Managed-by" = "Terraform"
  }
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.consul_cluster_vpc.id

  tags = {
    Name         = "Consul-Cluster-public-route"
    "Managed-by" = "Terraform"
  }
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.consul_internet_gateway.id
}
resource "aws_route_table_association" "public_route_table_association_1" {
  subnet_id      = aws_subnet.consul_cluster_public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "public_route_table_association_2" {
  subnet_id      = aws_subnet.consul_cluster_public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "public_route_table_association_3" {
  subnet_id      = aws_subnet.consul_cluster_public_subnet_3.id
  route_table_id = aws_route_table.public_route_table.id
}