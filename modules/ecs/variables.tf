//==========================================================================================================================================
//                                                         /modules/ecs/variables.tf
//==========================================================================================================================================

variable "vpc_id" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_task_definition" {
  type = object({
    name = string
    family = string
    cpu = string
    memory = string
  })
}

variable "ecr_image_uri" {
  type = string
}

variable "enable_ecr_pull_through" {
  description = "Enable creating an ECR pull-through cache rule (requires upstream auth if registry requires it)"
  type        = bool
  default     = false
}  


variable "s3_bucket_name" {
  type = string
}

variable "primary_domain" {
  type = string
}

variable "wordpress_secret_arn" {
  type = string
}

variable "ecs_execution_role_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_service_sg_name" {
  type = string
}

variable "ecs_task_desired_count" {
  type = number
}

variable "security_groups" {
  type = map(string)
}

variable "target_group_arn" {            
  type = string
}

variable "vpc_endpoints" {
  type = map(string)
}

variable "private_subnets_ids" {          
  type = list(string)
}

variable "vpc_endpoints_security_group_id" {     
  type = string
}

variable "target_group_arn_suffix" {      
  type = string
}
variable "load_balancer_arn_suffix" {
  type = string
}

variable "cloudfront_distribution_id" {
  type = string
}

variable "create_secretsmanager_endpoint" {
  description = "Whether to create the Secrets Manager VPC endpoint in this stack"
  type        = bool
  default     = true
}

variable "cloudfront_distribution_domain" {
  type = string
}


