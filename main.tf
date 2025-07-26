# Configure the AWS provider with a region specified by a variable
provider "aws" {
  region = var.aws_region # Uses the aws_region variable from variables.tf
}

# Backend module for Lambda, API Gateway, and DynamoDB resources
module "backend" {
  source     = "./modules/backend" # Path to the backend module
  aws_region = var.aws_region      # Pass the AWS region to the backend module
}

# Frontend module for S3 bucket and static website files
module "frontend" {
  source       = "./modules/frontend"        # Path to the frontend module
  api_endpoint = module.backend.api_endpoint # Pass the API Gateway endpoint from backend module
  aws_region   = var.aws_region             # Pass the AWS region to the frontend module
}