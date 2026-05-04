variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "upload_lambda_invoke_arn" {
  description = "Upload lambda invoke ARN"
  type        = string
}

variable "api_gateway_log_group_arn" {
  description = "CloudWatch log group ARN for API Gateway access logs"
  type        = string
}
