module "lambda_failover" {
  source = "../../../modules/iam"

  role_name = "lambda-failover-functions-role"
  assume_role_services = ["lambda.amazonaws.com"]
  policy_name = "lambda-failover-functions-policy"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
  
  inline_policy_statements = [
    # Logs
    {
      Effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
        resources = ["arn:aws:logs:*:*:*"]    
    },

    # CloudWatch
    {
      Effect = "Allow"
      actions = [
        "cloudwatch:DescribeAlarms",
        "cloudwatch:GetMetricStatistics"
      ]
      resources = ["*"]
    },

    # RDS
    {
      Effect = "Allow"
      actions = [
        "rds:DescribeDBInstances",
        "rds:PromoteReadReplica"
      ]
      resources = ["*"]
    },

    # ECS
    {
      Effect = "Allow"
      actions = [
        "ecs:DescribeServices",
        "ecs:UpdateService"
      ]
      Resource = ["*"]
    },
    
    # SecretManager 
    {
      effect = "Allow"

      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = [
        "arn:aws:secretsmanager:${var.dr_region}:${data.aws_caller_identity.current.account_id}:secret:wordpress-rds-replica-secret-*"
      ]
    }

  ]
}
