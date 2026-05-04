variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "suffix" {
  description = "Unique suffix for globally unique S3 bucket name"
  type        = string
}

variable "upload_lambda_memory" {
  description = "Memory in MB for upload lambda"
  type        = number
  default     = 512
}

variable "crop_lambda_memory" {
  description = "Memory in MB for crop lambda"
  type        = number
  default     = 512
}
