variable "aws_region" {
  description = "AWS region for the Lambda function"
  type        = string
  default     = "ap-east-2"
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "bugReportMailer"
}
variable "package_path" {
  description = "Path to the Lambda deployment zip file"
  type        = string
  default     = "../a.zip"
}

variable "tags" {
  description = "Tags applied to the Lambda function"
  type        = map(string)
  default     = {}
}
