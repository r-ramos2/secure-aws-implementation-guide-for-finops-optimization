# outputs.tf

output "s3_bucket_name" {
  value = aws_s3_bucket.secure_bucket.bucket
}

output "sns_topic_arn" {
  value = aws_sns_topic.cost_alerts.arn
}
