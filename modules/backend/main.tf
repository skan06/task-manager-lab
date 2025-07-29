# Data source to reference existing CloudWatch log group for Lambda
data "aws_cloudwatch_log_group" "lambda_logs" {
  name = "/aws/lambda/task-manager-function" # Reference existing log group
}

# Create a KMS key for encrypting Lambda environment variables
resource "aws_kms_key" "lambda_key" {
  description             = "KMS key for Lambda environment variables" # Description for AWS console
  deletion_window_in_days = 7                                  # Allow key deletion after 7 days
  enable_key_rotation     = true                               # Enable automatic key rotation
}

# Create a KMS key alias for easier reference
resource "aws_kms_alias" "lambda_key_alias" {
  name          = "alias/lambda-task-manager-key" # Alias name for the KMS key
  target_key_id = aws_kms_key.lambda_key.key_id   # Reference to the KMS key
}

# Create a DynamoDB table to store tasks
resource "aws_dynamodb_table" "task_table" {
  name           = "task-manager"                 # Name of the DynamoDB table
  billing_mode   = "PAY_PER_REQUEST"             # Free Tier compatible billing mode
  hash_key       = "task_id"                     # Primary key for the table
  attribute {
    name = "task_id"                            # Attribute name for the hash key
    type = "S"                                  # String type for the task_id
  }
  server_side_encryption {
    enabled     = true                         # Enable encryption at rest
    kms_key_arn = aws_kms_key.lambda_key.arn   # Use KMS key for encryption
  }
  point_in_time_recovery {
    enabled = true                             # Enable point-in-time recovery for backups
  }
  tags = {
    Name = "TaskManagerTable"                  # Tag for identification in AWS console
  }
}

# Create an IAM role for Lambda to assume
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role-${var.suffix}"       # Unique role name using suffix variable
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"             # Allow Lambda to assume this role
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" } # Lambda service principal
    }]
  })
}

# Attach AWS managed policy for Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # Policy for CloudWatch logging
}

# Custom policy to allow Lambda to interact with DynamoDB, KMS, and EC2 for VPC
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda-dynamodb-policy"                # Policy name
  role = aws_iam_role.lambda_exec_role.id        # Attach to Lambda role
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"                        # Added Query for additional DynamoDB operations
        ]
        Resource = aws_dynamodb_table.task_table.arn # Access to DynamoDB table
      },
      {
        Effect   = "Allow"
        Action   = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"                  # Added for KMS key operations
        ]
        Resource = aws_kms_key.lambda_key.arn    # KMS key ARN
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",          # Create ENI for Lambda in VPC
          "ec2:DescribeNetworkInterfaces",       # Describe ENIs for management
          "ec2:DeleteNetworkInterface"           # Delete ENIs when Lambda terminates
        ]
        Resource = "*"                           # Allow on all resources (required for ENI)
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",               # Ensure log stream creation
          "logs:PutLogEvents"                   # Ensure log event writing
        ]
        Resource = "${data.aws_cloudwatch_log_group.lambda_logs.arn}:*" # Reference existing log group
      }
    ]
  })
}

# Create a Lambda function for task management
resource "aws_lambda_function" "task_manager_lambda" {
  function_name    = "task-manager-function"                          # Lambda function name
  handler          = "lambda_function.lambda_handler"                 # Handler function in code
  runtime          = "python3.12"                                    # Python runtime version
  filename         = "${path.module}/../../lambda_function.zip"       # Path to zipped Lambda code
  source_code_hash = filebase64sha256("${path.module}/../../lambda_function.zip") # Code hash for updates
  role             = aws_iam_role.lambda_exec_role.arn                # IAM role for Lambda
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.task_table.name               # Pass DynamoDB table name
    }
  }
  kms_key_arn = aws_kms_key.lambda_key.arn                           # Encrypt environment variables
  tracing_config {
    mode = "Active"                                                 # Enable AWS X-Ray tracing
  }
  timeout       = 30                                                # Increase timeout to 30 seconds
  memory_size   = 256                                               # Increase memory for better performance
  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0 ? [1] : [] # Only include if subnets and SGs provided
    content {
      subnet_ids         = var.subnet_ids                           # Subnets for VPC configuration
      security_group_ids = var.security_group_ids                   # Security groups for VPC
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,                    # Ensure IAM role policy is attached
    aws_iam_role_policy.lambda_dynamodb_policy                     # Ensure DynamoDB and EC2 policy is attached
  ]
}

# Create a CloudWatch log group for API Gateway logs
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/task-manager-api"             # Log group name
  retention_in_days = 7                                             # Retain logs for 7 days
}

# Create an HTTP API Gateway for the Lambda function
resource "aws_apigatewayv2_api" "task_api" {
  name          = "task-manager-api"                                # API name
  protocol_type = "HTTP"                                            # HTTP protocol for API Gateway
  cors_configuration {
    allow_origins = [var.s3_website_endpoint != "" ? "http://${var.s3_website_endpoint}" : "http://localhost"] # Restrict to S3 website or localhost
    allow_methods = ["OPTIONS", "POST", "GET", "PUT", "DELETE"]    # Allowed HTTP methods
    allow_headers = ["Content-Type", "Authorization"]              # Allowed headers
    expose_headers = []                                            # No exposed headers
    max_age       = 3600                                          # CORS cache duration (1 hour)
  }
}

# Integrate API Gateway with Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                = aws_apigatewayv2_api.task_api.id
  integration_type      = "AWS_PROXY"                              # Proxy integration for Lambda
  integration_uri       = aws_lambda_function.task_manager_lambda.invoke_arn # Lambda ARN
  integration_method    = "POST"                                   # HTTP method for integration
  payload_format_version = "2.0"                                    # API Gateway v2 payload format
}

# Route for creating tasks (POST /tasks)
resource "aws_apigatewayv2_route" "create_task" {
  api_id    = aws_apigatewayv2_api.task_api.id
  route_key = "POST /tasks"                                       # Route for POST requests
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}" # Integration target
}

# Route for listing tasks (GET /tasks)
resource "aws_apigatewayv2_route" "get_tasks" {
  api_id    = aws_apigatewayv2_api.task_api.id
  route_key = "GET /tasks"                                        # Route for GET requests
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route for updating tasks (PUT /tasks/{task_id})
resource "aws_apigatewayv2_route" "update_task" {
  api_id    = aws_apigatewayv2_api.task_api.id
  route_key = "PUT /tasks/{task_id}"                              # Route for PUT requests
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route for deleting tasks (DELETE /tasks/{task_id})
resource "aws_apigatewayv2_route" "delete_task" {
  api_id    = aws_apigatewayv2_api.task_api.id
  route_key = "DELETE /tasks/{task_id}"                           # Route for DELETE requests
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Deploy the API to a default stage with access logs
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.task_api.id
  name        = "$default"                                         # Default stage name
  auto_deploy = true                                               # Auto-deploy changes
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn        # Log to CloudWatch
    format          = jsonencode({
      requestId      = "$context.requestId"                       # Log request ID
      ip             = "$context.identity.sourceIp"               # Log source IP
      requestTime    = "$context.requestTime"                    # Log request time
      httpMethod     = "$context.httpMethod"                     # Log HTTP method
      routeKey       = "$context.routeKey"                       # Log route key
      status         = "$context.status"                         # Log status code
      protocol       = "$context.protocol"                       # Log protocol
      errorMessage   = "$context.error.message"                  # Log error messages
    })
  }
}

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"                        # Unique statement ID
  action        = "lambda:InvokeFunction"                       # Permission to invoke Lambda
  function_name = aws_lambda_function.task_manager_lambda.function_name # Lambda function
  principal     = "apigateway.amazonaws.com"                    # API Gateway principal
  source_arn    = "${aws_apigatewayv2_api.task_api.execution_arn}/*/*" # API Gateway ARN
}