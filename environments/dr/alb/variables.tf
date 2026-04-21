//=============================================================================================================
//     SSL Variables
//=============================================================================================================

variable "primary_domain" {
    type = string  
    default = ""
}

variable "certificate_sans" {
  type = list(string)
  default = [ "" ]
}

variable "hosted_zone_id" {
    type = string
    default = ""
}

variable "provided_ssl_certificate_arn" {
    type = string
    default = ""
}


//=============================================================================================================
//     ALB Variables
//=============================================================================================================

variable "target_group_config" {
    type = object({
        name = string
        health_check_enabled = bool
        health_check_interval = number
        health_check_timeout = number
        healthy_threshold = number
        unhealthy_threshold = number
        matcher = string
    })
}

variable "alb_name" {
    type = string
}

