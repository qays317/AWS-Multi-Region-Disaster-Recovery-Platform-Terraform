
locals {
  checks = {

      "recheck-incident" = {
        timeout = 30
        environment = {
          PRIMARY_ALARM_NAME = var.primary_alarm_name
        }
      }
      
      "check-replica-readiness" ={ 
        timeout = 60
        environment = {
          DR_REGION                   = var.dr_region
          DR_REPLICA_IDENTIFIER       = var.dr_replica_identifier
          MAX_REPLICATION_LAG_SECONDS = tostring(var.max_replication_lag_seconds)
        }
      }

      "promote-replica" = {
        timeout = 60
        environment = {
          DR_REGION             = var.dr_region
          DR_REPLICA_IDENTIFIER = var.dr_replica_identifier
        }
      }
      
      "check-db-available" = {
        timeout = 60
        environment = {
          DR_REGION             = var.dr_region
          DR_REPLICA_IDENTIFIER = var.dr_replica_identifier
        }
      }

      "validate-db-writable" = {
        timeout = 60
        environment = {
          DB_SECRET_ARN = data.terraform_remote_state.dr_rds.outputs.wordpress_secret_arn
          DB_CONNECT_TIMEOUT = tostring(var.db_connect_timeout)
        }
      }

      "scaleup-dr-service" = {
        timeout = 60
        environment = {
          DR_REGION        = var.dr_region
          ECS_CLUSTER_NAME = var.ecs_cluster_name
          ECS_SERVICE_NAME = var.ecs_service_name
          DR_DESIRED_COUNT = tostring(var.dr_desired_count)
        }
        
      }
    
      "check-ecs-healthy" = {
        timeout = 60
        environment = {
          DR_REGION        = var.dr_region
          ECS_CLUSTER_NAME = var.ecs_cluster_name
          ECS_SERVICE_NAME = var.ecs_service_name
        }
      }
    
      "validate-application" = {
        timeout = 30
        environment = {
          APP_HEALTHCHECK_URL     = var.app_healthcheck_url
          APP_HEALTHCHECK_TIMEOUT = tostring(var.app_healthcheck_timeout)
          EXPECTED_STATUS_CODE    = tostring(var.expected_status_code)
        }
      }
  }
}

