data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "terraform_remote_state" "network" {
    backend = "s3"
    config = {
      bucket = var.state_bucket_name
      key = "environments/dr/network/terraform.tfstate"
      region = var.state_bucket_region
    }
}

data "terraform_remote_state" "iam" {
    backend = "s3"
    config = {
      bucket = var.state_bucket_name
      key = "environments/global/iam/terraform.tfstate"
      region = var.state_bucket_region
    }
}

data "terraform_remote_state" "dr_rds" {
    backend = "s3"
    config = {
      bucket = var.state_bucket_name
      key = "environments/dr/read_replica_rds/terraform.tfstate"
      region = var.state_bucket_region
    }
}

module "sg" {
  source = "../../../modules/sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr = data.terraform_remote_state.network.outputs.vpc_cidr
  security_group = var.security_group_config
  external_security_groups = {
    "DR-RDS-SG"                     = data.terraform_remote_state.dr_rds.outputs.dr_rds_sg_id
    "DR-SecretsManager-Endpoint-SG" = data.terraform_remote_state.dr_rds.outputs.dr_secret_manager_endpoint_sg_id
  }
  stage_tag = "DR Orchestration"
}

# Creating Lambda functions
module "lambda" {
  source = "../../../modules/lambda"
  name_prefix = "wordpress-operations"
  lambda_source_base = local.lambda_source_base
  function = local.lambda
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
      module.lambda.check_replica_readiness_arn, 
      module.lambda.promote_replica_arn,
      module.lambda.check_db_available_arn,
      module.lambda.validate_db_writable_arn,
      module.lambda.scaleup_dr_service_arn,
      module.lambda.check_ecs_healthy_arn,
      module.lambda.validate_application_arn        ] 
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
      check_replica_readiness_lambda_arn = module.lambda.check_replica_readiness_arn 
      promote_replica_lambda_arn         = module.lambda.promote_replica_arn
      check_db_available_lambda_arn      = module.lambda.check_db_available_arn
      validate_db_writable_lambda_arn    = module.lambda.validate_db_writable_arn
      scaleup_dr_service_lambda_arn      = module.lambda.scaleup_dr_service_arn
      check_ecs_healthy_lambda_arn       = module.lambda.check_ecs_healthy_arn
      validate_application_lambda_arn    = module.lambda.validate_application_arn    }
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
}

