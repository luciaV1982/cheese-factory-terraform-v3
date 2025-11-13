locals {
  project      = "cheese"
  env          = "global"
  bucket_name  = format("%s-tfstate-%s-%s", local.project, local.env, data.aws_caller_identity.this.account_id)
}

data "aws_caller_identity" "this" {}

module "tfstate_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket = local.bucket_name

  # Configuración moderna: sin ACLs, usando BucketOwnerEnforced
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"
  acl                      = null

  force_destroy               = false
  restrict_public_buckets     = true
  block_public_acls           = true
  block_public_policy         = true
  ignore_public_acls          = true

  versioning = {
    enabled = true
  }

  tags = {
    Project     = "The Cheese Factory"
    Terraform   = "true"
    ManagedBy   = "Terraform"
    Environment = local.env
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "tf-lock-cheese"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project     = "The Cheese Factory"
    ManagedBy   = "Terraform"
    Environment = local.env
  }
}
