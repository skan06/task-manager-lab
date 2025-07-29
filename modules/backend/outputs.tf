# Output the API Gateway endpoint for use by the frontend module
output "api_endpoint" {
  value = aws_apigatewayv2_api.task_api.api_endpoint # URL of the API Gateway
}
