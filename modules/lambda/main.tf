data "archive_file" "upload_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/../../lambdas/upload-lambda"
  output_path = "${path.module}/upload-lambda.zip"
}

data "archive_file" "crop_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/../../lambdas/crop-lambda"
  output_path = "${path.module}/crop-lambda.zip"
}

resource "aws_lambda_function" "upload" {
  function_name    = "image-processor-${var.environment}-upload"
  filename         = data.archive_file.upload_lambda.output_path
  source_code_hash = data.archive_file.upload_lambda.output_base64sha256
  role             = var.upload_lambda_role_arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  memory_size      = var.upload_lambda_memory
  timeout          = 30

  environment {
    variables = {
      S3_BUCKET     = var.bucket_name
      UPLOAD_PREFIX = "uploads/"
      ENVIRONMENT   = var.environment
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_upload_lambda_id]
  }

  depends_on = [var.upload_log_group_name]

  tags = {
    Name        = "image-processor-${var.environment}-upload"
    Environment = var.environment
  }
}

resource "aws_lambda_function" "crop" {
  function_name    = "image-processor-${var.environment}-crop"
  filename         = data.archive_file.crop_lambda.output_path
  source_code_hash = data.archive_file.crop_lambda.output_base64sha256
  role             = var.crop_lambda_role_arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  memory_size      = var.crop_lambda_memory
  timeout          = 60

  environment {
    variables = {
      S3_BUCKET        = var.bucket_name
      PROCESSED_PREFIX = "processed/"
      ENVIRONMENT      = var.environment
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_crop_lambda_id]
  }

  depends_on = [var.crop_log_group_name]

  tags = {
    Name        = "image-processor-${var.environment}-crop"
    Environment = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_crop" {
  event_source_arn        = var.sqs_queue_arn
  function_name           = aws_lambda_function.crop.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_permission" "apigw_upload" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
