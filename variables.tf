# variables.tf

variable "aws_region" {
  description = "The AWS region where resources will be deployed"
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name for secure storage"
  type        = string
}

variable "env" {
  description = "The environment to deploy (e.g., development, production)"
  default     = "development"
}

variable "sns_topic_arn" {
  description = "ARN of the SNS Topic for alerting"
  type        = string
}

variable "cost_threshold" {
  description = "The cost threshold for the CloudWatch Alarm (in USD)"
  default     = 500
}
