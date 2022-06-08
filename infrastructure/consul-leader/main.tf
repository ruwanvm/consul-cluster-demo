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
  instance_type               = var.instance_type
  key_name                    = var.keypair_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [data.aws_security_group.consul_security_group.id]
  subnet_id                   = data.aws_subnet.consul_subnet.id
  iam_instance_profile        = data.aws_iam_instance_profile.consul_iam_instance_profile.name
  private_ip                  = "10.1.0.4"
  tags = {
    "Name"       = "Consul Leader"
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

resource "aws_eip" "consul_leader_eip" {
  vpc = true
}

resource "aws_eip_association" "consul_leader_eip_allocation" {
  instance_id   = aws_instance.consul_leader.id
  allocation_id = aws_eip.consul_leader_eip.id
  depends_on = [
    aws_instance.consul_leader,
    aws_eip.consul_leader_eip
  ]
}

# Wait until EIP allocation to be completed ##################################
resource "time_sleep" "wait_30_seconds" {
  depends_on = [
    aws_eip.consul_leader_eip,
    aws_eip_association.consul_leader_eip_allocation
  ]
  create_duration = "30s"
}
##############################################################################

resource "null_resource" "create_consul_leader" {
  provisioner "local-exec" {
    working_dir = "../../configurations/"
    command     = "ansible-playbook -u ${local.ssh_user} -i ${aws_eip.consul_leader_eip.public_ip}, --private-key ../consul.pem consul-leader-setup.yml -e consul_bucket=${var.consul_bucket}"
  }
  triggers = {
    build_number = aws_instance.consul_leader.id
  }
  depends_on = [
    time_sleep.wait_30_seconds,
    aws_eip_association.consul_leader_eip_allocation
  ]
}