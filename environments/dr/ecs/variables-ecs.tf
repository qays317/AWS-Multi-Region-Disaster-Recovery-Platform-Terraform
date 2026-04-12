//=============================================================================================================
//     ECS Variables
//=============================================================================================================

variable "ecs_security_group_config" {
  type        = map(object({
    ingress = map(object({
      from_port = number
      to_port = number
      ip_protocol = string
      source_security_group_name = optional(string)
      cidr_block = optional(string)
    }))
    egress = optional(map(object({
      from_port = number
      to_port = number
      ip_protocol = string
      cidr_block = string
    })))
  }))
}

variable "ecr_image_uri" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_task_definition_config" {
  type = object({
    name = string
    family = string
    cpu = string
    memory = string
    rds_name = string
  })
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

variable "vpc_endpoints_config" {
  type = map(string)
}

variable "dr_media_s3_bucket" {
  type = string
}

variable "primary_domain" {
  type = string
}
