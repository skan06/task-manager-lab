# Configure the AWS provider with a region specified by a variable
provider "aws" {
  region = var.aws_region # Uses aws_region from variables.tf (e.g., us-east-1)
}

# Generate a random suffix for unique resource naming across modules
resource "random_id" "suffix" {
  byte_length = 4 # Creates an 8-character hex string for uniqueness
}

# Backend module for Lambda, API Gateway, and DynamoDB resources
module "backend" {
  source              = "./modules/backend"           # Path to backend module
  suffix              = random_id.suffix.hex          # Pass random suffix for unique naming
  s3_website_endpoint = module.frontend.s3_website_endpoint # Pass S3 website endpoint for CORS
  aws_region          = var.aws_region               # Pass AWS region
}

# Frontend module for S3 bucket and static website files
module "frontend" {
  source       = "./modules/frontend"                # Path to frontend module
  suffix       = random_id.suffix.hex                # Pass random suffix for unique naming
  api_endpoint = module.backend.api_endpoint          # Pass API Gateway endpoint
  aws_region   = var.aws_region                      # Pass AWS region
}

# Output the API Gateway endpoint
output "api_endpoint" {
  description = "The endpoint of the API Gateway"
  value       = module.backend.api_endpoint           # Reference backend module output
}

# Output the S3 website endpoint
output "s3_website_endpoint" {
  description = "The endpoint of the S3 website"
  value       = module.frontend.s3_website_endpoint   # Reference frontend module output
}