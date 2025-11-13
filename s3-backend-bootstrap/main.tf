data "aws_caller_identity" "this" {}

locals {
  project     = "cheese"
  env         = "global"
  account_id  = data.aws_caller_identity.this.account_id
  bucket_name = var.bucket_name
}

data "aws_iam_policy_document" "s3_backend_access" {
  statement {
    sid    = "AllowAnyoneAccessToStateFile"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]

    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/global/cheese/terraform.tfstate"
    ]
  }

  statement {
    sid    = "AllowAnyoneListBucket"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:ListBucket"]

    resources = ["arn:aws:s3:::${local.bucket_name}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["global/cheese/*"]
    }
  }
}

module "tfstate_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket = local.bucket_name
  policy = data.aws_iam_policy_document.s3_backend_access.json

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"
  acl                      = null

  force_destroy               = false
  restrict_public_buckets     = true
  block_public_acls           = true
  block_public_policy         = false
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
  name         = format("tf-lock-%s", local.project)
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