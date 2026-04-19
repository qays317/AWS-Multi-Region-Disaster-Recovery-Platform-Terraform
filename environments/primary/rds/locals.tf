

locals {

  rds_config = {
      engine_version = "8.0"
      instance_class = "db.t3.micro"
      username = "masteruser"        # Replace with your DB admin username
      db_username = "wordpressuser"      # Replace with your DB username
      db_name = "wordpressDB" 
      multi_az = false
      subnets_names = ["Prv-A", "Prv-B"]
      security_group_id = data.terraform_remote_state.network.outputs.rds_sg_id
  }
}

locals {

  lambda = {
      
      "primary-db-setup" ={ 
        timeout = 900
        role_arn = data.terraform_remote_state.iam.outputs.lambda_db_setup_role_arn
        vpc_config = {
            subnet_ids = data.terraform_remote_state.network.outputs.private_subnets_ids
            security_group_ids = [data.terraform_remote_state.network.outputs.db_setup_lambda_sg_id]
        }
        layer = true
        environment = {
            MASTER_SECRET_ARN   = module.rds.master_secret_arn
            WORDPRESS_SECRET_NAME = module.rds.wordpress_secret_name
            DB_HOST = split(":", module.rds.rds_endpoint)[0]
            DB_PORT = tostring(module.rds.rds_port)
            WORDPRESS_DB_NAME  = local.rds_config.db_name
            WORDPRESS_DB_USER  = local.rds_config.db_username
        }
      }
  }
}

locals {
  lambda_source_base = "${path.module}/../../../lambdas"
}
