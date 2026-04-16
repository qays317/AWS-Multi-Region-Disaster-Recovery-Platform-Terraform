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
      Actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resources = ["arn:aws:logs:*:*:*"]    
    },

    # CloudWatch
    {
      Effect = "Allow"
      Actions = [
        "cloudwatch:DescribeAlarms",
        "cloudwatch:GetMetricStatistics"
      ]
      Resources = ["*"]
    },

    # RDS
    {
      Effect = "Allow"
      Actions = [
        "rds:DescribeDBInstances",
        "rds:PromoteReadReplica"
      ]
      Resources = ["*"]
    },

    # ECS
    {
      Effect = "Allow"
      Actions = [
        "ecs:DescribeServices",
        "ecs:UpdateService"
      ]
      Resource = ["*"]
    },
    
    # SecretManager 
    {
      effect = "Allow"

      Actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resources = [
        "arn:aws:secretsmanager:${var.dr_region}:${data.aws_caller_identity.current.account_id}:secret:wordpress-rds-replica-secret-*"
      ]
    }
  ]
}
