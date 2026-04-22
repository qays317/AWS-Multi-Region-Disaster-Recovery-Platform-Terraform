variable "rds_replica_identifier" {
  description = "RDS read replica identifier in DR region"
  type        = string
}

variable "max_replication_lag_seconds" {
  description = "Maximum acceptable replication lag before promotion"
  type        = number
  default     = 30
}

variable "db_connect_timeout" {
  description = "DB connection timeout in seconds"
  type        = number
  default     = 5
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_desired_count" {
  type = number
  default = 2
}

variable "app_healthcheck" {
  type = object({
    path         = string
    timeout      = number
    status_code  = number
  })
  default = {
    path        = "/"
    timeout     = 10
    status_code = 200
  }
}
