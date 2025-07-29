# Output the S3 website URL
output "s3_website_url" {
  description = "Frontend website URL"                    # Description of the output
  value       = aws_s3_bucket_website_configuration.frontend_config.website_endpoint # S3 website endpoint
}
