output "bucket_id" {
  description = "The ID/name of the B2 bucket"
  value       = aws_s3_bucket.tofu_remote_state.id
}

output "bucket_arn" {
  description = "The ARN of the B2 bucket"
  value       = aws_s3_bucket.tofu_remote_state.arn
}

output "bucket_region" {
  description = "The region of the B2 bucket"
  value       = aws_s3_bucket.tofu_remote_state.region
}
