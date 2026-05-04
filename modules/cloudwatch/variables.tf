variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "dlq_name" {
  description = "Dead Letter Queue name for CloudWatch alarm"
  type        = string
}
