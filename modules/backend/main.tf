# Create a KMS key for Lambda environment encryption
resource "aws_kms_key" "lambda_key" {
  description             = "KMS key for Lambda environment variables"
  deletion_window_in_days = 7 # Allow key deletion after 7 days
  enable_key_rotation     = true # Enable automatic key rotation
}

# Create a KMS key alias
resource "aws_kms_alias" "lambda_key_alias" {
  name          = "alias/lambda-task-manager-key"
  target_key_id = aws_kms_key.lambda_key.key_id
}

# Create a DynamoDB table to store tasks
resource "aws_dynamodb_table" "task_table" {
  name           = "task-manager"
  billing_mode   = "PAY_PER_REQUEST" # Free Tier compatible
  hash_key       = "task_id"
  attribute {
    name = "task_id"
    type = "S"
  }
  server_side_encryption {
    enabled     = true # Enable encryption at rest
    kms_key_arn = aws_kms_key.lambda_key.arn # Use KMS key
  }
  point_in_time_recovery {
    enabled = true # Enable point-in-time recovery
  }
  tags = {
    Name = "TaskManagerTable"
  }
}

# Create an IAM role for Lambda to assume
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role-${random_id.suffix.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Attach AWS managed policy for Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy to allow Lambda to interact with DynamoDB and KMS
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda-dynamodb-policy"
  role = aws_iam_role.lambda_exec_role.id
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
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.task_table.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Encrypt", "kms:Decrypt"]
        Resource = aws_kms_key.lambda_key.arn
      }
    ]
  })
}

# Create a Lambda function for task management
resource "aws_lambda_function" "task_manager_lambda" {
  function_name    = "task-manager-function"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  filename         = "${path.module}/../../lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambda_function.zip")
  role             = aws_iam_role.lambda_exec_role.arn
  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.task_table.name }
  }
  kms_key_arn = aws_kms_key.lambda_key.arn # Encrypt environment variables
  tracing_config {
    mode = "Active" # Enable X-Ray tracing
  }
  vpc_config {
    subnet_ids         = var.subnet_ids # Use provided subnet IDs
    security_group_ids = var.security_group_ids # Use provided security group IDs
  }
}

# Create a CloudWatch log group for API Gateway logs
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/task-manager-api"
  retention_in_days = 7 # Retain logs for 7 days
}

# Create an HTTP API Gateway for the Lambda function
resource "aws_apigatewayv2_api" "task_api" {
  name          = "task-manager-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["http://${var.s3_website_endpoint}"] # Restrict CORS to S3 website
    allow_methods = ["OPTIONS", "POST", "GET", "PUT", "DELETE"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 3600
  }
}

# Integrate API Gateway with Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                = aws_apigatewayv2_api.task_api.id
  integration_type      = "AWS_PROXY"
  integration_uri       = aws_lambda_function.task_manager_lambda.invoke_arn
  integration_method    = "POST"
  payload_format_version = "2.0"
}

# Route for creating tasks (POST /tasks)
resource "aws_apigatewayv2_route" "create_task" {
  api_id    = aws_apigatewayv2_api.task_api.id
  route_key = "POST /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route for listing tasks (GET /tasks)
resource "aws_apigatewayv2_route" "get_tasks" {
  api_id    = aws_apigatewayv2_api.task_api.id
  route_key = "GET /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route for updating tasks (PUT /tasks/{task_id})
resource "aws_apigatewayv2_route" "update_task" {
  api_id    = aws_apigatewayv2_api.task_api.id
  route_key = "PUT /tasks/{task_id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route for deleting tasks (DELETE /tasks/{task_id})
resource "aws_apigatewayv2_route" "delete_task" {
  api_id    = aws_apigatewayv2_api.task_api.id
  route_key = "DELETE /tasks/{task_id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Deploy the API to a default stage with access logs
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.task_api.id
  name        = "$default"
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format          = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
    })
  }
}

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.task_manager_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.task_api.execution_arn}/*/*"
}
