//==========================================================================================================================================
//                                                   Subnet Group + RDS Instance
//==========================================================================================================================================

resource "aws_db_subnet_group" "wordpress" {
  name = "${var.rds_identifier}-subnet-group"
  subnet_ids = [for subnet_name in var.rds.subnets_names : var.subnets[subnet_name]]
}


resource "random_password" "db" {
  length  = 20
  special = true
}


resource "aws_db_instance" "rds" {
  identifier = var.rds_identifier
  engine = "mysql"
  engine_version = var.rds.engine_version
  instance_class = var.rds.instance_class
  multi_az = var.rds.multi_az 
  vpc_security_group_ids = [var.rds.security_group_id]
  db_subnet_group_name = aws_db_subnet_group.wordpress.name
  publicly_accessible = false
  allocated_storage = 20    
  storage_type = "gp2"             
  storage_encrypted = false
  username = var.rds.db_username
  password = random_password.db.result
  db_name = var.rds.db_name
  backup_retention_period = 7
  skip_final_snapshot = true
}


//==========================================================================================================================================
//                                                     Secrets Manager
//==========================================================================================================================================


resource "aws_secretsmanager_secret" "wordpress" {
  name = "${var.rds_identifier}-secret"
  description = "WordPress database credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "wordpress" {
  secret_id = aws_secretsmanager_secret.wordpress.id

  secret_string = jsonencode({
    username = var.rds.username
    password = random_password.db.result
    dbname   = var.rds.db_name
    host     = split(":", aws_db_instance.rds.endpoint)[0]
    port     = aws_db_instance.rds.port
  })
}
