# Output the API Gateway endpoint URL
output "api_endpoint" {
  description = "API Gateway URL"                     # Description of the output
  value       = aws_apigatewayv2_api.task_api.api_endpoint # Value from API Gateway
}
