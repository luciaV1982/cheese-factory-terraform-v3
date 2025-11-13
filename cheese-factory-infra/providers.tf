provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "cheese-tfstate-global-339712780971"
    key            = "global/cheese/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-lock-cheese"
    encrypt        = true
  }
}


