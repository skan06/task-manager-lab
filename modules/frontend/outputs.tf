# Output the S3 website endpoint for use in CORS configuration in the backend module
output "s3_website_endpoint" {
  value       = aws_s3_bucket_website_configuration.frontend_config.website_endpoint # Website URL
  description = "The endpoint of the S3 static website"
}