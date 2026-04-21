//=============================================================================================================
//     ECS Variables
//=============================================================================================================

variable "ecr_image_uri" {
  type = string
  default = ""
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

variable "ecs_task_desired_count" {
  type = number
}



variable "primary_media_s3_bucket" {
  type = string
}

variable "primary_domain" {
  type = string
}
