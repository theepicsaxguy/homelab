output "bucket_id" {
  description = "The ID/name of the B2 bucket created for state storage"
  value       = module.b2.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the B2 bucket"
  value       = module.b2.bucket_arn
}

output "bucket_endpoint" {
  description = "The S3-compatible endpoint for the B2 bucket"
  value       = var.b2.endpoint
}

output "bucket_region" {
  description = "The region of the B2 bucket"
  value       = var.b2.region
}
