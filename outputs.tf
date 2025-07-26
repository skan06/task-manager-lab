# Output the API Gateway endpoint
output "api_endpoint" {
  value = module.backend.api_endpoint # Get from backend module
}

# Output the S3 website URL
output "s3_website_url" {
  value = module.frontend.s3_website_url # Get from frontend module
}