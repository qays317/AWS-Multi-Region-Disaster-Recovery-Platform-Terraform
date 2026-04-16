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
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = ["arn:aws:logs:*:*:*"]    
    },

    # CloudWatch
    {
      Effect = "Allow"
      Action = [
        "cloudwatch:DescribeAlarms",
        "cloudwatch:GetMetricStatistics"
      ]
      Resource = ["*"]
    },

    # RDS
    {
      Effect = "Allow"
      Action = [
        "rds:DescribeDBInstances",
        "rds:PromoteReadReplica"
      ]
      Resource = ["*"]
    },

    # ECS
    {
      Effect = "Allow"
      Action = [
        "ecs:DescribeServices",
        "ecs:UpdateService"
      ]
      Resource = ["*"]
    },
    
    # SecretManager 
    {
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        "arn:aws:secretsmanager:${var.dr_region}:${data.aws_caller_identity.current.account_id}:secret:wordpress-rds-replica-secret-*"
      ]
    }
  ]
}
