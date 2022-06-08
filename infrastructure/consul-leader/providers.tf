terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.17.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.7.2"
    }
  }
}


provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}
provider "null" {

}

provider "time" {

}