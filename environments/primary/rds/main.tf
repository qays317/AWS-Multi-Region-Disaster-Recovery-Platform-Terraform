data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/global/iam/terraform.tfstate"
    region = var.state_bucket_region
  }
}

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config = {
      bucket = var.state_bucket_name
      key = "environments/primary/network/terraform.tfstate"
      region = var.state_bucket_region
    }
}

module "sg" {
  source = "../../../modules/sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_cidr = data.terraform_remote_state.vpc.outputs.vpc_cidr
  security_group = var.rds_security_group_config
  stage_tag = "RDS"
}

module "rds" {
  source = "../../../modules/rds"
  # VPC configuration
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  subnets = data.terraform_remote_state.vpc.outputs.subnets
  private_subnets_ids = data.terraform_remote_state.vpc.outputs.private_subnets_ids
  # SGs configuration
  security_groups = module.sg.rds_security_groups
  secretsmanager_endpoint_sg_name = var.secretsmanager_endpoint_sg_name
  # RDS configuration
  rds_identifier = var.rds_identifier
  rds = var.rds_config
}

locals {
  lambda_source_base = "${path.module}/../../../lambdas"
}

module "lambda" {
  source = "../../../modules/lambda"
  lambda_role_arn = data.terraform_remote_state.iam.outputs.lambda_db_setup_role_arn
  lambda_security_group_name = var.lambda_security_group_name
  name_prefix = "wordpress-infrastructure"
  lambda_source_base = local.lambda_source_base
  function = local.lambda
}


resource "aws_lambda_invocation" "db_bootstrap" {
  function_name = module.lambda.primary_db_setup_name

  input = jsonencode({
    trigger = "terraform"
  })

  depends_on = [
    module.lambda
  ]
}
