variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "sqs_queue_arn" {
  description = "Main SQS queue ARN"
  type        = string
}
