output "consul_iam_role_id" {
  value = aws_iam_role.consul_iam_role.id
}

output "consul_iam_role_arn" {
  value = aws_iam_role.consul_iam_role.arn
}

output "consul_instance_profile_name" {
  value = aws_iam_instance_profile.consul_instance_profile.name
}