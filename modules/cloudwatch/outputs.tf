output "upload_log_group_name" {
  value = aws_cloudwatch_log_group.upload_lambda.name
}

output "crop_log_group_name" {
  value = aws_cloudwatch_log_group.crop_lambda.name
}

output "api_gateway_log_group_arn" {
  value = aws_cloudwatch_log_group.api_gateway.arn
}
