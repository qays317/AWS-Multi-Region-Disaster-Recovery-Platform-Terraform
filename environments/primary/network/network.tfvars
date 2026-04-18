vpc_config = {
    name = "WordPress-VPC"
    cidr_block = "172.16.0.0/16"    
}

route_table_config = {
    Public-RT = {
        routes = {
            default = {
                cidr_block = "0.0.0.0/0"
                gateway = true
            }
        }
        subnets_names = ["Pub-A", "Pub-B"]
    }
    Private-RT = {
        routes = {}
        subnets_names = ["Prv-A", "Prv-B"]
    }
}

security_group_config = {
    RDS-SG = {
        ingress= {
            mysql_access = {
                ip_protocol = "tcp"
                from_port = 3306
                to_port = 3306
                vpc_cidr = true
            }
        }
    }
    DB-Setup-Lambda-SG = {
        egress = {
            mysql_access = {
                ip_protocol = "tcp"
                from_port = 3306
                to_port = 3306
                source_security_group_name = "RDS-SG"
            }
            https_access = {                       
                ip_protocol = "tcp"
                from_port = 443
                to_port = 443
                source_security_group_name = "SecretsManager-Endpoint-SG"
            }
        }
    }
    SecretsManager-Endpoint-SG = {
        ingress = {
            https_access = {
                ip_protocol = "tcp"
                from_port = 443
                to_port = 443
                vpc_cidr = true
            }
        }
    }
    ALB-SG = {
        ingress = {
            https_access = { 
                from_port = 443
                to_port = 443
                ip_protocol = "tcp"
                cidr_block = "0.0.0.0/0"
            }
        }
        egress = {
            ecs_access = {
                from_port = 80
                to_port = 80
                ip_protocol = "tcp"
                vpc_cidr = true
            }
        }
    }
    wordpress-service-SG = {
        ingress = {
            http = {
                from_port = 80
                to_port = 80 
                ip_protocol = "tcp"
                source_security_group_name = "ALB-SG"
            }
        }
        egress = {
            all = {
                from_port = 0
                to_port = 0
                ip_protocol = "-1"
                cidr_block = "0.0.0.0/0"
            }
        }
    }
    vpc-endpoints-SG = {
        ingress = {
            https = {
                ip_protocol = "tcp"
                from_port = 443
                to_port = 443
                source_security_group_name = "wordpress-service-SG"
            }
        }
    }
}

