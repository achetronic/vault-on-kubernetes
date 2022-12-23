terraform {
  required_version = ">= 1.1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.4"
    }
  }

  # DISCLAIMER:
  # These values are here as a fallback default values.
  # They will be overwritten by executing all this directory using the bash script called `operate.sh`
  backend "s3" {
    bucket         = "bucket-s3-dev-example-com"
    key            = "infrastructure/vault"
    profile        = "develop"
    region         = "eu-west-1"
    dynamodb_table = "tfstate-locks-dev"
  }
}

provider "aws" {
  profile = var.aws_environment
  region  = var.aws_region

  default_tags {
    tags = {
      environment = var.aws_environment
      region      = var.aws_region
      created_by  = "terraform"
      owner       = "infrastructure"
    }
  }
}
