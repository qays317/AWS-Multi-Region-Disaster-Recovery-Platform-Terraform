locals {
  checks = {
    "replica-failover-handler" = {
      timeout = 300
      environment = {
        DR_REGION                   = var.dr_region
        DR_REPLICA_IDENTIFIER       = var.rds_replica_identifier
        MAX_REPLICATION_LAG_SECONDS = tostring(var.max_replication_lag_seconds)
      }
    }

    "service-recovery-handler" = {
      timeout = 300
      environment = {
        DR_REGION        = var.dr_region
        ECS_CLUSTER_NAME = var.ecs.cluster_name
        ECS_SERVICE_NAME = var.ecs.service_name
        DR_DESIRED_COUNT = tostring(var.ecs.desired_count)
      }
    }

    "validate-db-writable" = {
      timeout = 60
      environment = {
        DB_SECRET_ARN      = data.terraform_remote_state.dr_rds.outputs.wordpress_secret_arn
        DB_CONNECT_TIMEOUT = tostring(var.db_connect_timeout)
        DR_REGION          = var.dr_region
      }
    }

    "validate-application" = {
      timeout = 30
      environment = {
        APP_HEALTHCHECK_URL     = var.app_healthcheck.path
        APP_HEALTHCHECK_TIMEOUT = tostring(var.app_healthcheck.timeout)
        EXPECTED_STATUS_CODE    = tostring(var.app_healthcheck.status_code)
      }
    }
  }
}
