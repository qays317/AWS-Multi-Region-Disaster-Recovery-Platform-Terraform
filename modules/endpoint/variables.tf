variable "vpc_id" {
    type = string
}

variable "private_subnets_ids" {
    type = list(string) 
}

variable "vpc_endpoints" {
  type = map(object({
    type = string
    security_group_id = optional(string)
  }))
}

variable "private_route_table_id" {
  type = list(string)
}
