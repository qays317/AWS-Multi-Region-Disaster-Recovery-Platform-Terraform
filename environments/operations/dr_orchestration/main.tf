data "terraform_remote_state" "dr_rds" {
    backend = "s3"
    config = {
      bucket = var.state_bucket_name
      key = "environments/dr/read_replica_rds/terraform.tfstate"
      region = var.state_bucket_region
    }
}

# Creating Lambda functions
module "lambda" {
  source = "../../../modules/lambda"
  name_prefix = "wordpress-operations"
  lambda_source_base = local.lambda_source_base
  function = local.checks
}

# Creating IAM role for State Machine 
module "iam" {
  source = "../../../modules/iam"

  role_name = "lambda-snf-orchestration-role"
  assume_role_services = ["states.amazonaws.com"]
  policy_name = "lambda-snf-orchestration-policy"
  
  inline_policy_statements = [
    {
      Effect = "Allow"

      Action = [
        "lambda:InvokeFunction"
      ]

      Resource = [
          module.lambda.replica_failover_handler_arn,
          module.lambda.service_recovery_handler_arn,
          module.lambda.validate_db_writable_arn,
          module.lambda.validate_application_arn
      ] 
    },

    {
      Effect = "Allow"

      Action = [
        "logs:CreateLogDelivery",
        "logs:GetLogDelivery",
        "logs:UpdateLogDelivery",
        "logs:DeleteLogDelivery",
        "logs:ListLogDeliveries",
        "logs:PutResourcePolicy",
        "logs:DescribeResourcePolicies",
        "logs:DescribeLogGroups"
      ]

      Resource = ["*"]
    }
  ]

    depends_on = [
        module.lambda
    ]
}



# Creating State Machine
resource "aws_cloudwatch_log_group" "sfn_logs" {
  name              = "/aws/lambda/dr-failover-orchestrator"
  retention_in_days = 7
}

resource "aws_sfn_state_machine" "dr_failover_orchestrator" {
  name     = "wordpress-dr-failover-orchestrator"
  role_arn = module.iam.role_arn
  type     = "STANDARD"

  definition = templatefile(
    "${path.module}/../../../stepfunctions/dr-failover-orchestrator.asl.json",
    {
        replica_failover_handler_lambda_arn = module.lambda.replica_failover_handler_arn
        service_recovery_handler_lambda_arn = module.lambda.service_recovery_handler_arn
        validate_db_writable_lambda_arn     = module.lambda.validate_db_writable_arn
        validate_application_lambda_arn     = module.lambda.validate_application_arn
     }
   )

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = false
  }

  tags = {
    Name = "wordpress-dr-failover-orchestrator"
  }

  depends_on = [
    module.lambda
  ]
}

