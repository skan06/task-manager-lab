# Variable for AWS region
variable "aws_region" {
  description = "AWS region to deploy" # Description of the variable
  type        = string                # Variable type
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "s3_website_endpoint" {
  type    = string
  default = ""
}