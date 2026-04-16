

locals {
  lambda = {
      
      "primary-db-setup" ={ 
        timeout = 900
        role_arn = data.terraform_remote_state.vpc.outputs.lambda_db_setup_role_arn
        vpc_config = {
            subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets_ids
            security_group_ids = [module.sg.db_setup_lambda_security_group_id]
        }
        environment = {
            MASTER_SECRET_ARN = module.rds.master_secret_arn
            WORDPRESS_SECRET_NAME = "${var.rds_identifier}-secret"
            DB_HOST = split(":", module.rds.rds_endpoint)[0]
            DB_PORT = tostring(module.rds.rds_port)
            WORDPRESS_DB_NAME  = var.rds_config.db_name
            WORDPRESS_DB_USER  = var.rds_config.db_username
        }
      }
  }
}
