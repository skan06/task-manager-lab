# Output the API Gateway endpoint from the backend module
output "api_endpoint" {
  value       = module.backend.api_endpoint # URL of the API Gateway
  description = "The endpoint of the API Gateway for the task manager"
}

# Output the S3 website endpoint from the frontend module
output "s3_website_endpoint" {
  value       = module.frontend.s3_website_endpoint # Website URL
  description = "The endpoint of the S3 static website"
}