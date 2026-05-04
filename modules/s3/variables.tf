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

variable "sqs_policy_done" {
  description = "Dependency token to ensure SQS policy exists before S3 notification"
  type        = any
  default     = null
}
