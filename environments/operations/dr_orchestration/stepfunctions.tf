resource "aws_cloudwatch_log_group" "sfn_logs" {
  name              = "/aws/vendedlogs/states/${local.name_prefix}-dr-failover-orchestrator"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_sfn_state_machine" "dr_failover_orchestrator" {
  name     = "${local.name_prefix}-dr-failover-orchestrator"
  role_arn = aws_iam_role.sfn_role.arn
  type     = "STANDARD"

  definition = templatefile(
    "${local.stepfunction_base}/dr-failover-orchestrator.asl.json",
    {
      recheck_incident_lambda_arn        = aws_lambda_function.main["recheck_incident"].arn
      check_replica_readiness_lambda_arn = aws_lambda_function.main["check_replica_readiness"].arn
      promote_replica_lambda_arn         = aws_lambda_function.main["promote_replica"].arn
      check_db_available_lambda_arn      = aws_lambda_function.main["check_db_available"].arn
      validate_db_writable_lambda_arn    = aws_lambda_function.main["validate_db_writable"].arn
      scaleup_dr_service_lambda_arn      = aws_lambda_function.main["scaleup_dr_service"].arn
      check_ecs_healthy_lambda_arn       = aws_lambda_function.main["check_ecs_healthy"].arn
      validate_application_lambda_arn    = aws_lambda_function.main["validate_application"].arn
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

  tags = local.common_tags
}