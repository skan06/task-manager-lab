# Variable for unique suffix to ensure resource naming uniqueness
variable "suffix" {
  description = "Unique suffix for resource naming"
  type        = string
}

# Variable for S3 website endpoint for CORS configuration
variable "s3_website_endpoint" {
  description = "S3 website endpoint for CORS"
  type        = string
}

# Variable for AWS region
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

# Optional variable for subnet IDs (for VPC configuration, if used)
variable "subnet_ids" {
  description = "List of subnet IDs for Lambda VPC configuration"
  type        = list(string)
  default     = [] # Default to empty list if not provided
}

# Optional variable for security group IDs (for VPC configuration, if used)
variable "security_group_ids" {
  description = "List of security group IDs for Lambda"
  type        = list(string)
  default     = [] # Default to empty list if not provided
}