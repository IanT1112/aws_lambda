variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "upload_lambda_role_arn" {
  description = "IAM role ARN for upload lambda"
  type        = string
}

variable "crop_lambda_role_arn" {
  description = "IAM role ARN for crop lambda"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "sg_upload_lambda_id" {
  description = "Security group ID for upload lambda"
  type        = string
}

variable "sg_crop_lambda_id" {
  description = "Security group ID for crop lambda"
  type        = string
}

variable "sqs_queue_arn" {
  description = "Main SQS queue ARN"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN"
  type        = string
}

variable "upload_log_group_name" {
  description = "CloudWatch log group dependency for upload lambda"
  type        = any
  default     = null
}

variable "crop_log_group_name" {
  description = "CloudWatch log group dependency for crop lambda"
  type        = any
  default     = null
}

variable "upload_lambda_memory" {
  description = "Memory size in MB for upload lambda"
  type        = number
  default     = 256
}

variable "crop_lambda_memory" {
  description = "Memory size in MB for crop lambda"
  type        = number
  default     = 512
}
