

data "aws_security_group" "consul_security_group" {
  id = var.security_group
}

data "aws_iam_instance_profile" "consul_iam_instance_profile" {
  name = var.iam_instance_profile
}

data "aws_subnet" "consul_subnet_1" {
  id = var.subnet_id_1
}
data "aws_subnet" "consul_subnet_2" {
  id = var.subnet_id_2
}
data "aws_subnet" "consul_subnet_3" {
  id = var.subnet_id_3
}

resource "aws_launch_configuration" "consul_server_launch_configuration" {
  name                        = "consul_server_launch_configuration_${var.consul_version}"
  image_id                    = var.consul_ami_id
  instance_type               = "t2.micro"
  iam_instance_profile        = data.aws_iam_instance_profile.consul_iam_instance_profile.name
  security_groups             = [data.aws_security_group.consul_security_group.id]
  key_name                    = var.keypair_id
  associate_public_ip_address = true
  user_data                   = <<EOF
#!/bin/sh
sudo systemctl start consul
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "consul_client_launch_configuration" {
  name                        = "consul_client_launch_configuration_${var.consul_version}"
  image_id                    = var.consul_ami_id
  instance_type               = "t2.micro"
  iam_instance_profile        = data.aws_iam_instance_profile.consul_iam_instance_profile.name
  security_groups             = [data.aws_security_group.consul_security_group.id]
  key_name                    = var.keypair_id
  associate_public_ip_address = true
  user_data                   = <<EOF
#!/bin/sh
sudo systemctl start consul-client
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "consul_servers_auto_scaling_group" {
  max_size             = 6
  min_size             = 0
  desired_capacity     = 3
  name                 = "consul_servers_auto_scaling_group"
  launch_configuration = aws_launch_configuration.consul_server_launch_configuration.name
  vpc_zone_identifier  = [data.aws_subnet.consul_subnet_1.id, data.aws_subnet.consul_subnet_2.id, data.aws_subnet.consul_subnet_3.id]
  termination_policies = ["OldestInstance"]
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "consul-server"
  }
  tag {
    key                 = "Managed-by"
    propagate_at_launch = true
    value               = "Terraform"
  }
  depends_on = [
    aws_launch_configuration.consul_server_launch_configuration
  ]
}

resource "aws_autoscaling_group" "consul_client_auto_scaling_group" {
  max_size             = 6
  min_size             = 0
  desired_capacity     = 3
  name                 = "consul_clients_auto_scaling_group"
  launch_configuration = aws_launch_configuration.consul_client_launch_configuration.name
  vpc_zone_identifier  = [data.aws_subnet.consul_subnet_1.id, data.aws_subnet.consul_subnet_2.id, data.aws_subnet.consul_subnet_3.id]
  termination_policies = ["OldestInstance"]
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "consul-client"
  }
  tag {
    key                 = "Managed-by"
    propagate_at_launch = true
    value               = "Terraform"
  }
  depends_on = [
    aws_launch_configuration.consul_client_launch_configuration
  ]
}