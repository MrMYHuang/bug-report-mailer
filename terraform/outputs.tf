output "lambda_function_name" {
  description = "Created Lambda function name"
  value       = aws_lambda_function.bug_report_mailer.function_name
}

output "lambda_function_arn" {
  description = "Created Lambda function ARN"
  value       = aws_lambda_function.bug_report_mailer.arn
}

output "lambda_role_arn" {
  description = "IAM role ARN created for the Lambda"
  value       = aws_iam_role.lambda_exec.arn
}

output "api_invoke_url" {
  description = "API Gateway invoke URL for the Lambda trigger"
  value       = "https://${aws_api_gateway_rest_api.bug_report_mailer_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.bug_report_mailer_default.stage_name}/${var.function_name}"
}
