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

resource "aws_instance" "consul_leader" {
  ami                         = var.consul_ami_id
  instance_type               = "t2.micro"
  key_name                    = var.keypair_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [data.aws_security_group.consul_security_group.id]
  subnet_id                   = data.aws_subnet.consul_subnet.id
  iam_instance_profile        = data.aws_iam_instance_profile.consul_iam_instance_profile.name
  private_ip                  = var.private_ip
  user_data                   = <<EOF
#!/bin/sh
sudo systemctl start consul
EOF
  tags = {
    "Name"       = var.name_tag
    "Managed-by" = "Terraform"
  }
  provisioner "remote-exec" {
    inline = ["echo 'wait until SSH is ready'"]
    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file("../../consul.pem")
      host        = aws_instance.consul_leader.public_ip
    }
  }
}