resource "aws_iam_policy" "consul_iam_role_policy" {
  name        = "consul_iam_role_policy"
  description = "Policy to provide AWS permission to Consul instances"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource" : ["arn:aws:s3:::${var.consul_config_s3_bucket}/*"]
      }
    ]
  })
  tags = {
    "Name"       = "consul_iam_role_policy"
    "Managed-by" = "Terraform"
  }
}

resource "aws_iam_role" "consul_iam_role" {
  name        = "consul_iam_role"
  description = "Allow Consul instances to access AWS resources"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Action" : "sts:AssumeRole",
      "Principal" : {
        "Service" : "ec2.amazonaws.com"
      },
      "Effect" : "Allow",
      "Sid" : ""
    }]
  })
  tags = {
    "Name"       = "consul_iam_role"
    "Managed-by" = "Terraform"
  }
}

resource "aws_iam_policy_attachment" "consul_iam_role_policy_attachment" {
  name       = "consul_iam_role_policy_attachment"
  roles      = [aws_iam_role.consul_iam_role.name]
  policy_arn = aws_iam_policy.consul_iam_role_policy.arn
}

resource "aws_iam_instance_profile" "consul_instance_profile" {
  name = "consul_instance_profile"
  role = aws_iam_role.consul_iam_role.name
  tags = {
    "Name"       = "consul_iam_instance_profile"
    "Managed-by" = "Terraform"
  }
}