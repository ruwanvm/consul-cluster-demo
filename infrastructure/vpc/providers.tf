terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.17.1"
    }
  }
}
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}