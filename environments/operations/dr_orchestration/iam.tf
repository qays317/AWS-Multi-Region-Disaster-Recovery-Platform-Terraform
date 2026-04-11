data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Assumed by Lambda functions 
resource "aws_iam_role" "lambda_role" {
  name = "${local.name_prefix}-dr-orchestration-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags = local.common_tags
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid = "AllowLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid = "AllowCloudWatchRead"
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:GetMetricStatistics"
    ]

    resources = ["*"]
  }

  statement {
    sid = "AllowRDSActions"
    effect = "Allow"

    actions = [
      "rds:DescribeDBInstances",
      "rds:PromoteReadReplica"
    ]

    resources = ["*"]
  }

  statement {
    sid = "AllowECSActions"
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]

    resources = ["*"]
  }
  statement {
    sid    = "AllowSecretsManagerRead"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      data.terraform_remote_state.dr_rds.outputs.wordpress_secret_arn
    ]
  }

}

resource "aws_iam_policy" "lambda_policy" {
  name = "${local.name_prefix}-dr-orchestration-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


# Remote state for DR RDS (to get WordPress secret)
data "terraform_remote_state" "dr_rds" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/dr/read_replica_rds/terraform.tfstate"
    region = var.state_bucket_region
  }
}










data "aws_iam_policy_document" "sfn_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Assumed by Step Functions state machine
resource "aws_iam_role" "sfn_role" {
  name = "${local.name_prefix}-dr-orchestration-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume_role.json
  tags = local.common_tags
}

data "aws_iam_policy_document" "sfn_policy" {
  statement {
    sid = "AllowInvokeLambdas"
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      for name in keys(local.checks) : aws_lambda_function.main[name].arn
    ]
  }

  statement {
    sid = "AllowStateMachineLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "sfn_policy" {
  name = "${local.name_prefix}-dr-orchestration-sfn-policy"
  policy = data.aws_iam_policy_document.sfn_policy.json
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "sfn_policy_attach" {
  role = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_policy.arn
}



