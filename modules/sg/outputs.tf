//==========================================================================================================================================
//                                                         /modules/sg/outputs.tf
//==========================================================================================================================================
output "rds_sg_id" {
    value = aws_security_group.main["RDS-SG"].id
}

output "db_setup_lambda_sg_id" {
    value = try(aws_security_group.main["DB-Setup-Lambda-SG"].id, null)
}

output "secretsmanager_endpoint_sg_id" {
    value = aws_security_group.main["SecretsManager-Endpoint-SG"].id
}

output "alb_sg_id" {
    value = aws_security_group.main["ALB-SG"].id
}

output "wordpress_service_sg_id" {
    value = aws_security_group.main["wordpress-service-SG"].id
}

output "vpc_endpoints_sg_id" {
    value = aws_security_group.main["vpc-endpoints-SG"].id
}

output "lambda_validate_db_writable_sg_id" {
    value = try(aws_security_group.main["Lambda-validate-db-writable-SG"].id, null)
}
