data "aws_subnet" "consul_subnet_1" {
  id = var.subnet_id_1
}
data "aws_subnet" "consul_subnet_2" {
  id = var.subnet_id_2
}
data "aws_subnet" "consul_subnet_3" {
  id = var.subnet_id_3
}
data "aws_security_group" "consul_security_group" {
  id = var.security_group
}
data "aws_iam_instance_profile" "consul_iam_instance_profile" {
  name = var.iam_instance_profile
}
module "leader_primary" {
  source               = "./modules/leader"
  name_tag             = "Consul Leader - primary"
  subnet_id            = data.aws_subnet.consul_subnet_1.id
  consul_ami_id        = var.consul_ami_id
  keypair_id           = var.keypair_id
  security_group       = data.aws_security_group.consul_security_group.id
  iam_instance_profile = data.aws_iam_instance_profile.consul_iam_instance_profile.name
  private_ip           = "10.1.0.4"
}

module "leader_secondary" {
  source               = "./modules/leader"
  name_tag             = "Consul Leader - secondary"
  subnet_id            = data.aws_subnet.consul_subnet_2.id
  consul_ami_id        = var.consul_ami_id
  keypair_id           = var.keypair_id
  security_group       = data.aws_security_group.consul_security_group.id
  iam_instance_profile = data.aws_iam_instance_profile.consul_iam_instance_profile.name
  private_ip           = "10.1.0.20"
  depends_on = [
    module.leader_primary
  ]
}

module "leader_backup" {
  source               = "./modules/leader"
  name_tag             = "Consul Leader - backup"
  subnet_id            = data.aws_subnet.consul_subnet_3.id
  consul_ami_id        = var.consul_ami_id
  keypair_id           = var.keypair_id
  security_group       = data.aws_security_group.consul_security_group.id
  iam_instance_profile = data.aws_iam_instance_profile.consul_iam_instance_profile.name
  private_ip           = "10.1.0.36"
  depends_on = [
    module.leader_primary,
    module.leader_secondary
  ]
}

data "aws_eip" "consul_primary_leader_eip" {
  public_ip = var.leader_public_ip
}

resource "aws_eip_association" "leader_primary_eip_association" {
  instance_id   = module.leader_primary.consul_leader_instance_id
  allocation_id = data.aws_eip.consul_primary_leader_eip.id
}