//=============================================================================================================
//     SSL Variables
//=============================================================================================================

variable "primary_domain" {
    type = string
}

variable "certificate_sans" {
  type = list(string)
  default = [ "" ]
}

variable "hosted_zone_id" {                    
    type = string
}

variable "provided_ssl_certificate_arn" {                
    type = string
    default = ""
}
