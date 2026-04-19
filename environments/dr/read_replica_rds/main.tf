data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/dr/network/terraform.tfstate"
    region = var.state_bucket_region
  }
}

# Remote state for primary RDS (to get WordPress secret)
data "terraform_remote_state" "primary_rds" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/primary/rds/terraform.tfstate"
    region = var.state_bucket_region
  }
}

# Get primary RDS instance info
data "aws_db_instance" "primary" {
  db_instance_identifier = var.rds_identifier
  provider = aws.primary
}

resource "aws_db_instance" "read_replica" {
  identifier = var.rds_replica_identifier
  
  replicate_source_db = data.aws_db_instance.primary.db_instance_arn
  
  # Instance configuration
  instance_class = "db.t3.micro"
  
  # Network configuration
  db_subnet_group_name = aws_db_subnet_group.rr.name
  vpc_security_group_ids = [data.terraform_remote_state.outputs.read_replica_sg_id]
  
  # Read replicas inherit most settings from source
  skip_final_snapshot = true

  tags = {
    Name = "WordPress-DR-ReadReplica"
    Environment = "DR"
  }
}

# Subnet group for DR
resource "aws_db_subnet_group" "rr" {
  name = "wordpress-dr-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnets_ids
  
  tags = {
    Name = "WordPress DR DB subnet group"
  }
}

# Get primary WordPress secret to copy credentials
data "aws_secretsmanager_secret_version" "primary_wordpress" {
  provider = aws.primary
  secret_id = data.terraform_remote_state.primary_rds.outputs.wordpress_secret_id
}

# Create DR secret with same WordPress credentials
resource "aws_secretsmanager_secret" "rr" {
  name = "${var.rds_replica_identifier}-secret"
  description = "WordPress database credentials for DR"
  recovery_window_in_days = 0
}

# Store same WordPress credentials but with DR database host
resource "aws_secretsmanager_secret_version" "rr" {
  secret_id = aws_secretsmanager_secret.rr.id
  secret_string = jsonencode({
    username = jsondecode(data.aws_secretsmanager_secret_version.primary_wordpress.secret_string).username
    password = jsondecode(data.aws_secretsmanager_secret_version.primary_wordpress.secret_string).password
    dbname = jsondecode(data.aws_secretsmanager_secret_version.primary_wordpress.secret_string).dbname
    host = split(":", aws_db_instance.read_replica.endpoint)[0]
    port = aws_db_instance.read_replica.port
  })
}

# VPC Endpoint for Secret
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  service_name = "com.amazonaws.${var.dr_region}.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnets_ids
  security_group_ids = [data.terraform-remote_state.network.outputs.secretsmanager_endpoint_sg_id]
  private_dns_enabled = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = "secretsmanager:*"
        Resource = [
          aws_secretsmanager_secret.rr.arn,
        ]
      }
    ]
  })

  tags = { Name = "dr-secretsmanager-endpoint" }
}
