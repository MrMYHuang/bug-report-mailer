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

resource "aws_api_gateway_integration" "bug_report_mailer_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.bug_report_mailer_api.id
  resource_id             = aws_api_gateway_resource.bug_report_mailer_resource.id
  http_method             = aws_api_gateway_method.bug_report_mailer_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.bug_report_mailer.invoke_arn
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
      aws_api_gateway_integration.bug_report_mailer_proxy.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.bug_report_mailer_proxy,
  ]
}

resource "aws_api_gateway_stage" "bug_report_mailer_default" {
  rest_api_id   = aws_api_gateway_rest_api.bug_report_mailer_api.id
  deployment_id = aws_api_gateway_deployment.bug_report_mailer_deployment.id
  stage_name    = "default"
}
