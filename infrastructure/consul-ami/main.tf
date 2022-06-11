locals {
  ssh_user = "ec2-user"
}
data "aws_security_group" "consul_security_group" {
  id = var.security_group
}
data "aws_subnet" "consul_subnet" {
  id = var.subnet_id
}
data "aws_iam_instance_profile" "consul_iam_instance_profile" {
  name = var.iam_instance_profile
}

resource "aws_instance" "consul_ami_master" {
  ami                         = var.base_ami_id
  instance_type               = var.instance_type
  key_name                    = var.keypair_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [data.aws_security_group.consul_security_group.id]
  subnet_id                   = data.aws_subnet.consul_subnet.id
  iam_instance_profile        = data.aws_iam_instance_profile.consul_iam_instance_profile.name
  private_ip                  = "10.1.0.14"
  tags = {
    "Name"       = "Consul AMI Master"
    "Managed-by" = "Terraform"
  }
  provisioner "remote-exec" {
    inline = ["echo 'wait until SSH is ready'"]
    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file("../../consul.pem")
      host        = aws_instance.consul_ami_master.public_ip
    }
  }
}


resource "null_resource" "setup_consul" {
  provisioner "local-exec" {
    working_dir = "../../configurations/"
    command     = "ansible-playbook -u ${local.ssh_user} -i ${aws_instance.consul_ami_master.public_ip}, --private-key ../consul.pem consul-ami-setup.yml -e consul_version=${var.consul_version}"
  }
  triggers = {
    consul_version  = var.consul_version
    master_instance = aws_instance.consul_ami_master.id
  }
  depends_on = [
    aws_instance.consul_ami_master
  ]
}

locals {
  ami_name = "consul-ami-${var.consul_version}"
}

resource "aws_ami_from_instance" "consul_ami" {
  name               = local.ami_name
  source_instance_id = aws_instance.consul_ami_master.id
  tags = {
    "Name"       = local.ami_name
    "Managed-by" = "Terraform"
  }

  depends_on = [
    null_resource.setup_consul
  ]
}

