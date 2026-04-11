data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  lambda_source_base = "${path.module}/../../../lambdas"
  stepfunction_base  = "${path.module}/../../../stepfunctions"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Component   = "dr-orchestration"
    ManagedBy   = "Terraform"
  }
}