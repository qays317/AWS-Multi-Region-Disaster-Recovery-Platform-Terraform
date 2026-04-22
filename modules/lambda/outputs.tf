output "primary_db_setup_name" {
  value = try(aws_lambda_function.main["primary-db-setup"].function_name, null)
}

output "replica_failover_handler_arn" {
  value = try(aws_lambda_function.main["replica-failover-handler"].arn, null)
}

output "service_recovery_handler_arn" {
  value = try(aws_lambda_function.main["service-recovery-handler"].arn, null)
}

output "validate_db_writable_arn" {
  value = try(aws_lambda_function.main["validate-db-writable"].arn, null)
}

output "validate_application_arn" {
  value = try(aws_lambda_function.main["validate-application"].arn, null)
}
