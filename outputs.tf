# Output the API Gateway endpoint for accessing the task manager API
output "api_endpoint" {
  description = "The endpoint of the API Gateway"
  value       = module.backend.api_endpoint # Reference backend module output
}

# Output the S3 website endpoint for accessing the frontend
output "s3_website_endpoint" {
  description = "The endpoint of the S3 website"
  value       = module.frontend.s3_website_endpoint # Reference frontend module output
}