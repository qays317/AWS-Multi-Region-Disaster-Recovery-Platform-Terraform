output "state_machine_name" {
  value = aws_sfn_state_machine.dr_failover_orchestrator.name
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.dr_failover_orchestrator.arn
}

output "recheck_incident_lambda_arn" {
  value = aws_lambda_function.main["recheck_incident"].arn
}

output "check_replica_readiness_lambda_arn" {
  value = aws_lambda_function.main["check_replica_readiness"].arn
}

output "promote_replica_lambda_arn" {
  value = aws_lambda_function.main["promote_replica"].arn
}

output "check_db_available_lambda_arn" {
  value = aws_lambda_function.main["check_db_available"].arn
}

output "validate_db_writable_lambda_arn" {
  value = aws_lambda_function.main["validate_db_writable"].arn
}

output "scaleup_dr_service_lambda_arn" {
  value = aws_lambda_function.main["scaleup_dr_service"].arn
}

output "check_ecs_healthy_lambda_arn" {
  value = aws_lambda_function.main["check_ecs_healthy"].arn
}

output "validate_application_lambda_arn" {
  value = aws_lambda_function.main["validate_application"].arn
}