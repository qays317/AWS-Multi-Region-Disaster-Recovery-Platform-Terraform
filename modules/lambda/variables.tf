variable "lambda_source_base" {
    type = string
}

variable "name_prefix" {
    type = string
}

variable "lambda_security_group_name" {
    type = string
}

variable "lambda_role_arn" {
    type = string
}

variable "function" {
  type = map(object({
    timeout = number
    environment = map(string)
    role_arn = string
    layer = bool
    vpc_config = optional(object({
      subnet_ids = list(string)
      security_group_ids = list(string)
    }))
  }))
}

