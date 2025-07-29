# Variable for AWS region
variable "aws_region" {
  type    = string
  default = "us-east-1" # Default region if not specified
}

# Variable for random suffix to ensure unique resource names
variable "suffix" {
  type    = string
  default = ""
}

# Variable for VPC subnet IDs for Lambda
variable "subnet_ids" {
  type    = list(string)
  default = []
}

# Variable for VPC security group IDs for Lambda
variable "security_group_ids" {
  type    = list(string)
  default = []
}

# Variable for S3 website endpoint for CORS configuration
variable "s3_website_endpoint" {
  type    = string
  default = ""
}
