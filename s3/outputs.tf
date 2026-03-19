output "website_endpoint" {
  description = "S3 static website endpoint (HTTP only)"
  value       = module.s3_static_website.s3_bucket_website_endpoint
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_static_website.s3_bucket_arn
}

output "bucket_id" {
  description = "Name of the S3 bucket"
  value       = module.s3_static_website.s3_bucket_id
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = module.s3_static_website.s3_bucket_bucket_regional_domain_name
}

output "bucket_region" {
  description = "Region of the S3 bucket"
  value       = module.s3_static_website.s3_bucket_region
}

output "content_hash" {
  description = "Combined hash of website content files, used to trigger CloudFront invalidation"
  value       = md5("${aws_s3_object.index.etag}-${aws_s3_object.error.etag}")
}
