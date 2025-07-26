terraform {
  backend "s3" {
    bucket         = "task-manager-terraform-state-sk06h" # S3 bucket for state storage
    key            = "task-manager/terraform.tfstate"    # Path for state file
    region         = "us-east-1"                         # AWS region
    dynamodb_table = "terraform-locks"                   # DynamoDB table for locking
  }
}