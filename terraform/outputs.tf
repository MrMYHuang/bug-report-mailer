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

output "api_custom_domain_name" {
  description = "API Gateway custom domain name"
  value       = aws_api_gateway_domain_name.bug_report_mailer_custom_domain.domain_name
}

output "api_custom_domain_target_domain_name" {
  description = "Regional target domain name for DNS alias record"
  value       = aws_api_gateway_domain_name.bug_report_mailer_custom_domain.regional_domain_name
}

output "api_custom_domain_target_hosted_zone_id" {
  description = "Regional hosted zone ID for DNS alias record"
  value       = aws_api_gateway_domain_name.bug_report_mailer_custom_domain.regional_zone_id
}

output "api_custom_domain_invoke_url" {
  description = "Custom domain URL for the Lambda trigger"
  value       = "https://${aws_api_gateway_domain_name.bug_report_mailer_custom_domain.domain_name}/${var.function_name}"
}
