# Create KeyPair
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
}
resource "aws_key_pair" "ec2_key" {
  key_name   = "consul_key"
  public_key = tls_private_key.rsa_key.public_key_openssh
  tags = {
    "Name"       = "consul_key"
    "Managed-by" = "Terraform"
  }
}
resource "local_file" "private_key_file" {
  content         = tls_private_key.rsa_key.private_key_pem
  filename        = "../../consul.pem"
  file_permission = "0600"
}

# Create Security Group
data "http" "workstation_ip" {
  url = "https://api.ipify.org"
}
data "aws_vpc" "consul_vpc" {
  id = var.consul_vpc_id
}
resource "aws_security_group" "consul_server_sg" {
  name   = "consul_server_sg"
  vpc_id = data.aws_vpc.consul_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.workstation_ip.body)}/32"]
    description = "SSH host ip"
  }
  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.consul_vpc.cidr_block]
    description = "Server RPC address"
  }
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.consul_vpc.cidr_block]
    description = "TCP - Serf LAN port"
  }
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.consul_vpc.cidr_block]
    description = "UDP - Serf LAN port"
  }
  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.consul_vpc.cidr_block]
    description = "TCP - Serf WAN port"
  }
  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.consul_vpc.cidr_block]
    description = "UDP - Serf WAN port"
  }
  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.consul_vpc.cidr_block]
  }
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP / HTTP API"
  }
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.consul_vpc.cidr_block]
    description = "TCP - DNS server"
  }
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.consul_vpc.cidr_block]
    description = "UDP - DNS server"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name"       = "consul_security_group"
    "Managed-by" = "Terraform"
  }
}