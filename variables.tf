# Variable for AWS region
variable "aws_region" {
  default     = "us-east-1"      # Default region
  description = "AWS region to deploy" # Description of the variable
  type        = string           # Variable type
}