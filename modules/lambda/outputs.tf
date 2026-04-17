output "primary_db_setup_name" {
    value = aws_lambda_function.main["primary-db-setup"].function_name
}

output "snf_functions_arns" {
    value = try({for k, v in aws_lambda_function.main : k => v.arn
                  if lookup( v.tags, "Component", "") == "DR orchestration"}, null)   
}

output "check_replica_readiness_arn" {
    value = try({for k, v in aws_lambda_function.main : k => v.arn
                  if lookup( v.tags, "Name", "") == "check-replica-readiness"}, null)   
}

output "promote_replica_arn" {
    value = try({for k, v in aws_lambda_function.main : k => v.arn
                  if lookup( v.tags, "Name", "") == "promote-replica"}, null)   
}


output "check_db_available_arn" {
    value = try({for k, v in aws_lambda_function.main : k => v.arn
                  if lookup( v.tags, "Name", "") == "check-db-available"}, null)   
}

output "validate_db_writable_arn" {
    value = try({for k, v in aws_lambda_function.main : k => v.arn
                  if lookup( v.tags, "Name", "") == "validate-db-writable"}, null)   
}

output "scaleup_dr_service_arn" {
    value = try({for k, v in aws_lambda_function.main : k => v.arn
                  if lookup( v.tags, "Name", "") == "scaleup-dr-service"}, null)   
}

output "check_ecs_healthy_arn" {
    value = try({for k, v in aws_lambda_function.main : k => v.arn
                  if lookup( v.tags, "Name", "") == "check-ecs-healthy"}, null)   
}

output "validate_application_arn" {
    value = try({for k, v in aws_lambda_function.main : k => v.arn
                  if lookup( v.tags, "Name", "") == "validate-application"}, null)   
}

