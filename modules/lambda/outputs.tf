output "primary_db_setup_name" {
    value = aws_lambda_function.main["primary-db-setup"].function_name
}
