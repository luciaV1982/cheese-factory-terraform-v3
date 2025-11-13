output "tfstate_bucket" {
  value = module.tfstate_bucket.s3_bucket_id
}

output "dynamodb_table" {
  value = aws_dynamodb_table.tf_lock.name
}
