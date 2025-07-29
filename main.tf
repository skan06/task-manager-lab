# Configure the AWS provider with a region specified by a variable
provider "aws" {
  region = var.aws_region # Uses aws_region from variables.tf (e.g., us-east-1)
}

# Generate a random suffix for unique resource naming across modules
resource "random_id" "suffix" {
  byte_length = 4 # Creates an 8-character hex string for uniqueness
}

# Create a new VPC for the task manager lab to isolate resources
resource "aws_vpc" "task_manager_vpc" {
  cidr_block           = "10.0.0.0/16" # VPC CIDR block for private network
  enable_dns_hostnames = true          # Enable DNS hostnames for Lambda connectivity
  enable_dns_support   = true          # Enable DNS support for resolving AWS service endpoints
  tags = {
    Name = "task-manager-vpc" # Tag for identification in AWS console
  }
}

# Create a subnet in us-east-1a for Lambda high availability
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.task_manager_vpc.id # Associate with the VPC
  cidr_block        = "10.0.1.0/24"              # Subnet CIDR for IP range
  availability_zone = "us-east-1a"               # Availability Zone for redundancy
  tags = {
    Name = "task-manager-subnet-a" # Tag for identification
  }
}

# Create a subnet in us-east-1b for Lambda high availability
resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.task_manager_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "task-manager-subnet-b"
  }
}

# Create a security group for the Lambda function to control network access
resource "aws_security_group" "lambda_sg" {
  vpc_id = aws_vpc.task_manager_vpc.id # Associate with the VPC
  name   = "task-manager-lambda-sg"   # Name for identification
  egress {
    from_port   = 0            # Allow all outbound traffic
    to_port     = 0            # All ports
    protocol    = "-1"         # All protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic to any IP
  }
  ingress {
    from_port   = 443          # Allow HTTPS for Lambda to access AWS APIs
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "task-manager-lambda-sg"
  }
}

# Backend module for Lambda, API Gateway, and DynamoDB resources
module "backend" {
  source              = "./modules/backend"           # Path to backend module
  suffix              = random_id.suffix.hex          # Pass random suffix for unique naming
  subnet_ids          = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id] # Pass subnet IDs for Lambda VPC
  security_group_ids  = [aws_security_group.lambda_sg.id] # Pass security group ID
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