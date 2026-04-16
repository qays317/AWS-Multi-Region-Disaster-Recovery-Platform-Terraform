dr_rds_security_group_config = {
    DR-RDS-SG = {
        ingress= {
            mysql_access = {
                ip_protocol = "tcp"
                from_port = 3306
                to_port = 3306
                vpc_cidr = true
            }
        }
    }
    Lambda-validate-db-writable-SG = {
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
}
