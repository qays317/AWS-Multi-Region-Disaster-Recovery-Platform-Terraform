//==========================================================================================================================================
//                                                   Subnet Group + RDS Instance
//==========================================================================================================================================

resource "aws_db_subnet_group" "wordpress" {
  name = "${var.rds_identifier}-subnet-group"
  subnet_ids = [for subnet_name in var.rds.subnets_names : var.subnets[subnet_name]]
}

resource "aws_db_instance" "rds" {
  identifier = var.rds_identifier
  engine = "mysql"
  engine_version = var.rds.engine_version
  instance_class = var.rds.instance_class
  multi_az = var.rds.multi_az 
  vpc_security_group_ids = [var.security_groups[var.rds.security_group_name]]
  db_subnet_group_name = aws_db_subnet_group.wordpress.name
  publicly_accessible = false
  allocated_storage = 20    
  storage_type = "gp2"             
  storage_encrypted = false
  username = var.rds.username     
  db_name = var.rds.db_name
  password = var.rds.rds_password
  manage_master_user_password = true
  backup_retention_period = 7
  skip_final_snapshot = true
}


//==========================================================================================================================================
//                                                    Secrets + Secrets Manager Endpoint
//==========================================================================================================================================

resource "aws_secretsmanager_secret" "wordpress" {
  name = "${var.rds_identifier}-secret"
  description = "WordPress database credentials"
  recovery_window_in_days = 0
}

data "aws_region" "current" {}  

# VPC Endpoint for Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids = var.private_subnets_ids
  security_group_ids = [var.security_groups[var.secretsmanager_endpoint_sg_name]]
  private_dns_enabled = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = "secretsmanager:*"
        Resource = [
          aws_secretsmanager_secret.wordpress.arn,
          aws_db_instance.rds.master_user_secret[0].secret_arn
        ]
      }
    ]
  })

  tags = { Name = "secretsmanager-endpoint" }
}

