variable "security_group_config" {
    type = map(object({
        vpc_name = string
        ingress = optional(map(object({
            ip_protocol = string
            from_port = number
            to_port = number
            cidr_block = optional(string)
            vpc_cidr = optional(bool)
            source_security_group_name = optional(string)
        })))
        egress = optional(map (object({
            ip_protocol = string
            from_port = number
            to_port = number
            cidr_block = optional(string)
            vpc_cidr = optional(bool)
            source_security_group_name = optional(string)
        })) )
    }))
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "wordpress-dr"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "Region where orchestration resources will be created"
  type        = string
  default = "eu-central-1"
}

variable "rds_replica_identifier" {
  description = "RDS read replica identifier in DR region"
  type        = string
}

variable "max_replication_lag_seconds" {
  description = "Maximum acceptable replication lag before promotion"
  type        = number
  default     = 30
}

variable "ecs_cluster_name" {
  description = "ECS cluster name in DR region"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name in DR region"
  type        = string
}

variable "dr_desired_count" {
  description = "Desired count for DR ECS service during failover"
  type        = number
  default     = 2
}

variable "db_connect_timeout" {
  description = "DB connection timeout in seconds"
  type        = number
  default     = 5
}

variable "app_healthcheck_url" {
  description = "Direct DR application healthcheck URL"
  type        = string
  default = "/"
}

variable "app_healthcheck_timeout" {
  description = "Timeout for application validation"
  type        = number
  default     = 10
}

variable "expected_status_code" {
  description = "Expected application healthcheck status code"
  type        = number
  default     = 200
}
