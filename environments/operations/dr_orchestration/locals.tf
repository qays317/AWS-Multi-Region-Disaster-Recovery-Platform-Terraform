locals {
  checks = {
    "replica-failover-handler" = {
      timeout = 300
      role_arn = data.terraform_remote_state.iam.outputs.lambda_failover_role_arn
      layer = false
      environment = {
        DR_REGION                   = var.dr_region
        DR_REPLICA_IDENTIFIER       = var.rds_replica_identifier
        MAX_REPLICATION_LAG_SECONDS = tostring(var.max_replication_lag_seconds)
      }
    }

    "service-recovery-handler" = {
      timeout = 300
      role_arn = data.terraform_remote_state.iam.outputs.lambda_failover_role_arn
      layer = false
      environment = {
        DR_REGION        = var.dr_region
        ECS_CLUSTER_NAME = var.ecs_cluster_name
        ECS_SERVICE_NAME = var.ecs_service_name
        DR_DESIRED_COUNT = tostring(var.ecs_desired_count)
      }
    }

    "validate-db-writable" = {
      timeout = 60
      role_arn = data.terraform_remote_state.iam.outputs.lambda_failover_role_arn
      layer = true
        vpc_config = {
          subnet_ids = data.terraform_remote_state.dr_network.outputs.private_subnets_ids
          security_group_ids = [
            data.terraform_remote_state.dr_network.outputs.validate_db_writable_lambda_sg_id
          ]
        }
      environment = {
        DB_SECRET_ARN      = data.terraform_remote_state.dr_rds.outputs.wordpress_secret_arn
        DB_CONNECT_TIMEOUT = tostring(var.db_connect_timeout)
        DR_REGION          = var.dr_region
      }
    }

    "validate-application" = {
      timeout = 30
      role_arn = data.terraform_remote_state.iam.outputs.lambda_failover_role_arn
      layer = false
      environment = {
        APP_HEALTHCHECK_URL     = var.app_healthcheck.path
        APP_HEALTHCHECK_TIMEOUT = tostring(var.app_healthcheck.timeout)
        EXPECTED_STATUS_CODE    = tostring(var.app_healthcheck.status_code)
      }
    }
  }

  lambda_source_base = "${path.module}/../../../lambdas"
}
