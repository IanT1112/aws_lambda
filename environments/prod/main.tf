terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "image-processor"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

locals {
  bucket_name = "image-processor-${var.environment}-images-${var.suffix}"
}

module "networking" {
  source      = "../../modules/networking"
  environment = var.environment
  aws_region  = var.aws_region
}

module "sqs" {
  source      = "../../modules/sqs"
  environment = var.environment
  bucket_name = local.bucket_name
}

module "s3" {
  source          = "../../modules/s3"
  environment     = var.environment
  bucket_name     = local.bucket_name
  sqs_queue_arn   = module.sqs.queue_arn
  sqs_policy_done = module.sqs.policy_done
}

module "cloudwatch" {
  source      = "../../modules/cloudwatch"
  environment = var.environment
  dlq_name    = module.sqs.dlq_name
}

module "iam" {
  source        = "../../modules/iam"
  environment   = var.environment
  bucket_name   = local.bucket_name
  sqs_queue_arn = module.sqs.queue_arn
}

module "api_gateway" {
  source                    = "../../modules/api_gateway"
  environment               = var.environment
  upload_lambda_invoke_arn  = module.lambda.upload_lambda_invoke_arn
  api_gateway_log_group_arn = module.cloudwatch.api_gateway_log_group_arn
}

module "lambda" {
  source                    = "../../modules/lambda"
  environment               = var.environment
  bucket_name               = local.bucket_name
  upload_lambda_role_arn    = module.iam.upload_lambda_role_arn
  crop_lambda_role_arn      = module.iam.crop_lambda_role_arn
  private_subnet_ids        = module.networking.private_subnet_ids
  sg_upload_lambda_id       = module.networking.sg_upload_lambda_id
  sg_crop_lambda_id         = module.networking.sg_crop_lambda_id
  sqs_queue_arn             = module.sqs.queue_arn
  api_gateway_execution_arn = module.api_gateway.execution_arn
  upload_log_group_name     = module.cloudwatch.upload_log_group_name
  crop_log_group_name       = module.cloudwatch.crop_log_group_name
  upload_lambda_memory      = var.upload_lambda_memory
  crop_lambda_memory        = var.crop_lambda_memory
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${module.api_gateway.api_endpoint}/upload"
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = local.bucket_name
}
