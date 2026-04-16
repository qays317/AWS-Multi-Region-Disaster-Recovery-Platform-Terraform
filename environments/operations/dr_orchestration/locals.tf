
locals {
  lambda = {
      
      "check-replica-readiness" ={ 
        timeout = 60
        role = data.terraform_remote_state.iam.lambda_failover_role_arn
        layer = false
        environment = {
          DR_REGION                   = var.dr_region
          DR_REPLICA_IDENTIFIER       = var.rds_replica_identifier
          MAX_REPLICATION_LAG_SECONDS = tostring(var.max_replication_lag_seconds)
        }
        component = "DR Orchestration"
      }

      "promote-replica" = {
        timeout = 60
        role = data.terraform_remote_state.iam.lambda_failover_role_arn
        layer = false
        environment = {
          DR_REGION             = var.dr_region
          DR_REPLICA_IDENTIFIER = var.rds_replica_identifier
        }
        component = "DR Orchestration"
      }
      
      "check-db-available" = {
        timeout = 60
        role = data.terraform_remote_state.iam.lambda_failover_role_arn
        layer = false
        environment = {
          DR_REGION             = var.dr_region
          DR_REPLICA_IDENTIFIER = var.rds_replica_identifier
        }
        component = "DR Orchestration"
      }

      "validate-db-writable" = {
        timeout = 60
        role = data.terraform_remote_state.iam.lambda_failover_role_arn
        layer = true
        vpc_config = {
          subnet_ids = data.terraform_remote_state.network.outputs.private_subnets_ids
          security_group_ids = [module.sg.db_setup_lambda_security_group_id]
        }
        environment = {
          DB_SECRET_ARN = data.terraform_remote_state.dr_rds.outputs.wordpress_secret_arn
          DB_CONNECT_TIMEOUT = tostring(var.db_connect_timeout)
          DR_REGION = var.dr_region
        }
        component = "DR Orchestration"
      }

      "scaleup-dr-service" = {
        timeout = 60
        role = data.terraform_remote_state.iam.lambda_failover_role_arn
        layer = false
        environment = {
          DR_REGION        = var.dr_region
          ECS_CLUSTER_NAME = var.ecs_cluster_name
          ECS_SERVICE_NAME = var.ecs_service_name
          DR_DESIRED_COUNT = tostring(var.dr_desired_count)
        }
        component = "DR Orchestration"
      }
    
      "check-ecs-healthy" = {
        timeout = 60
        role = data.terraform_remote_state.iam.lambda_failover_role_arn
        layer = false
        environment = {
          DR_REGION        = var.dr_region
          ECS_CLUSTER_NAME = var.ecs_cluster_name
          ECS_SERVICE_NAME = var.ecs_service_name
        }
        component = "DR Orchestration"
      }
    
      "validate-application" = {
        timeout = 30
        role = data.terraform_remote_state.iam.lambda_failover_role_arn
        layer = false
        environment = {
          APP_HEALTHCHECK_URL     = var.app_healthcheck_url
          APP_HEALTHCHECK_TIMEOUT = tostring(var.app_healthcheck_timeout)
          EXPECTED_STATUS_CODE    = tostring(var.expected_status_code)
        }
        component = "DR Orchestration"
      }
  }
}

locals {
  lambda_source_base = "${path.module}/../../../lambdas"
}
