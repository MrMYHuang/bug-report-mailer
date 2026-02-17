resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "bug_report_mailer" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs24.x"

  filename         = var.package_path
  source_code_hash = filebase64sha256(var.package_path)

  timeout     = 63
  memory_size = 128

  architectures = ["arm64"]

  ephemeral_storage {
    size = 512
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = var.tags
}

resource "aws_api_gateway_rest_api" "bug_report_mailer_api" {
  name        = "${var.function_name}-API"
  description = "Created by Terraform"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "bug_report_mailer_resource" {
  rest_api_id = aws_api_gateway_rest_api.bug_report_mailer_api.id
  parent_id   = aws_api_gateway_rest_api.bug_report_mailer_api.root_resource_id
  path_part   = var.function_name
}

resource "aws_api_gateway_method" "bug_report_mailer_any" {
  rest_api_id   = aws_api_gateway_rest_api.bug_report_mailer_api.id
  resource_id   = aws_api_gateway_resource.bug_report_mailer_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "bug_report_mailer_options" {
  rest_api_id   = aws_api_gateway_rest_api.bug_report_mailer_api.id
  resource_id   = aws_api_gateway_resource.bug_report_mailer_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "bug_report_mailer_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.bug_report_mailer_api.id
  resource_id             = aws_api_gateway_resource.bug_report_mailer_resource.id
  http_method             = aws_api_gateway_method.bug_report_mailer_any.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.bug_report_mailer.arn}/invocations"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"
  timeout_milliseconds    = 29000
}

resource "aws_api_gateway_method_response" "bug_report_mailer_any_200" {
  rest_api_id = aws_api_gateway_rest_api.bug_report_mailer_api.id
  resource_id = aws_api_gateway_resource.bug_report_mailer_resource.id
  http_method = aws_api_gateway_method.bug_report_mailer_any.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Origin"  = false
  }
}

resource "aws_api_gateway_integration_response" "bug_report_mailer_any_200" {
  rest_api_id = aws_api_gateway_rest_api.bug_report_mailer_api.id
  resource_id = aws_api_gateway_resource.bug_report_mailer_resource.id
  http_method = aws_api_gateway_method.bug_report_mailer_any.http_method
  status_code = aws_api_gateway_method_response.bug_report_mailer_any_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_integration" "bug_report_mailer_options" {
  rest_api_id          = aws_api_gateway_rest_api.bug_report_mailer_api.id
  resource_id          = aws_api_gateway_resource.bug_report_mailer_resource.id
  http_method          = aws_api_gateway_method.bug_report_mailer_options.http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  timeout_milliseconds = 29000

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "bug_report_mailer_options_200" {
  rest_api_id = aws_api_gateway_rest_api.bug_report_mailer_api.id
  resource_id = aws_api_gateway_resource.bug_report_mailer_resource.id
  http_method = aws_api_gateway_method.bug_report_mailer_options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Origin"  = false
  }
}

resource "aws_api_gateway_integration_response" "bug_report_mailer_options_200" {
  rest_api_id = aws_api_gateway_rest_api.bug_report_mailer_api.id
  resource_id = aws_api_gateway_resource.bug_report_mailer_resource.id
  http_method = aws_api_gateway_method.bug_report_mailer_options.http_method
  status_code = aws_api_gateway_method_response.bug_report_mailer_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_lambda_permission" "allow_apigateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bug_report_mailer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bug_report_mailer_api.execution_arn}/*/*/${var.function_name}"
}

resource "aws_api_gateway_deployment" "bug_report_mailer_deployment" {
  rest_api_id = aws_api_gateway_rest_api.bug_report_mailer_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.bug_report_mailer_resource.id,
      aws_api_gateway_method.bug_report_mailer_any.id,
      aws_api_gateway_method.bug_report_mailer_options.id,
      aws_api_gateway_integration.bug_report_mailer_proxy.id,
      aws_api_gateway_integration.bug_report_mailer_options.id,
      aws_api_gateway_method_response.bug_report_mailer_any_200.id,
      aws_api_gateway_method_response.bug_report_mailer_options_200.id,
      aws_api_gateway_integration_response.bug_report_mailer_any_200.id,
      aws_api_gateway_integration_response.bug_report_mailer_options_200.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.bug_report_mailer_proxy,
    aws_api_gateway_integration.bug_report_mailer_options,
  ]
}

resource "aws_api_gateway_stage" "bug_report_mailer_default" {
  rest_api_id   = aws_api_gateway_rest_api.bug_report_mailer_api.id
  deployment_id = aws_api_gateway_deployment.bug_report_mailer_deployment.id
  stage_name    = "default"
}
