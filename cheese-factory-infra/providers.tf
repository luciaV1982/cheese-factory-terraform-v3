provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "cheese-tfstate-global-villalobos"
    key            = "global/cheese/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-lock-cheese"
    encrypt        = true
  }
}


