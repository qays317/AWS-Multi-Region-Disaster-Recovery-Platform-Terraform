//==========================================================================================================================================
//                                                         /modules/rds/outputs.tf
//==========================================================================================================================================

output "wordpress_secret_id" {                                 # For referencing in DR region
    value = aws_secretsmanager_secret.wordpress.id
}

output "wordpress_secret_arn" {                                # For container secrets injection
    value = aws_secretsmanager_secret.wordpress.arn
}

output "master_secret_arn" {
    value = aws_secretsmanager_secret.master.arn
}

output "wordpress_secret_name" {
    value = aws_secretsmanager_secret.wordpress.name
}

output "rds_port" {
    value = aws_db_instance.rds.port
}

output "rds_endpoint" {
    value = aws_db_instance.rds.endpoint
}
