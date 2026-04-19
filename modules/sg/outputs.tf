//==========================================================================================================================================
//                                                         /modules/sg/outputs.tf
//==========================================================================================================================================
output "rds_sg_id" {
    value = aws_security_group.main["RDS-SG"].id
}

output "db_setup_lambda_sg_id" {
    value = aws_security_group.main["DB-Setup-Lambda-SG"].id
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



/*
output "rds_security_groups" {
    value = { for k, v in aws_security_group.main : k => v.id
              if lookup( v.tags, "Stage", "") == "RDS" }
}

output "alb_security_group_id" {
    value = try([ for k, v in aws_security_group.main : v.id
                  if lookup( v.tags, "Stage", "") == "ALB"][0], null )
}

output "ecs_security_groups" {
    value = try({for k, v in aws_security_group.main : k => v.id
                  if lookup( v.tags, "Stage", "") == "ECS"}, null) 
}

output "vpc_endpoints_security_group_id" {
    value = try([ for k, v in aws_security_group.main : v.id
                  if lookup( v.tags, "Name", "") == "vpc-endpoints-SG"][0], null ) 
}

output "db_setup_lambda_security_group_id" {
    value = try([ for k, v in aws_security_group.main : v.id 
                  if lookup( v.tags, "Name", "") == "Lambda-SG"][0], null)  
}

output "dr_rds_sg_id" {
    value = try([ for k, v in aws_security_group.main : v.id
                  if lookup( v.tags, "Name", "") == "DR-RDS-SG"][0], null ) 
}

output "dr_secret_manager_endpoint_sg_id" {
    value = try([ for k, v in aws_security_group.main : v.id
                  if lookup( v.tags, "Name", "") == "DR-SecretsManager-Endpoint-SG"][0], null ) 
}

output "lambda-validate-db-writable_sg_id" {
    value = try([ for k, v in aws_security_group.main : v.id
                  if lookup( v.tags, "Name", "") == "Lambda-validate-db-writable-SG"][0], null ) 
}

*/


