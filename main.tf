# main.tf

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "secure_bucket" {
  bucket        = var.bucket_name
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "ArchiveOldFiles"
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }

  tags = {
    Environment = var.env
    Owner       = "FinOpsTeam"
    CostCenter  = "CloudOps"
    Project     = "CostOptimization"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "LambdaCostOptimizationPolicy"
  description = "Allow Lambda to read AWS cost data and send SNS notifications"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ce:GetCostAndUsage",
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_exec_role.name
}

resource "aws_lambda_function" "cost_monitor_lambda" {
  function_name = "CostMonitorLambda"
  
  s3_bucket = aws_s3_bucket.secure_bucket.bucket
  s3_key    = "lambda/cost_monitor_lambda.zip"
  
  handler = "lambda_function.lambda_handler"
  runtime = "python3.8"

  role = aws_iam_role.lambda_exec_role.arn
}

resource "aws_sns_topic" "cost_alerts" {
  name = "CostAlerts"
}

resource "aws_cloudwatch_metric_alarm" "cost_alarm" {
  alarm_name          = "CostThresholdExceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  threshold           = var.cost_threshold

  alarm_actions = [
    aws_sns_topic.cost_alerts.arn
  ]

  dimensions = {
    ServiceName = "AWS"
  }
}
