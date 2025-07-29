# Variable for AWS region
variable "aws_region" {
  type    = string
  default = "us-east-1" # Default region
}

# Variable for API Gateway endpoint
variable "api_endpoint" {
  type    = string
  default = ""
}

# Variable for random suffix to ensure unique bucket name
variable "suffix" {
  type    = string
  default = ""
}