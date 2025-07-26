# Variable for AWS region
variable "aws_region" {
  description = "AWS region to deploy"
  type        = string
}

# Variable for API Gateway endpoint
variable "api_endpoint" {
  description = "API Gateway endpoint URL" # Description of the variable
  type        = string                   # Variable type
}