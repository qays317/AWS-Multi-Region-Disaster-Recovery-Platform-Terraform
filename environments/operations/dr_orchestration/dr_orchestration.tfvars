lambda-validate-db-writable-sg-config = {
   Lambda-validate-db-writable-SG = {
        egress = {
            mysql_access = {
                ip_protocol = "tcp"
                from_port = 3306
                to_port = 3306
                source_security_group_name = "DR-RDS-SG"
            }
            https_access = {                       
                ip_protocol = "tcp"
                from_port = 443
                to_port = 443
                source_security_group_name = "DR-SecretsManager-Endpoint-SG"
            }
        }
    }
}

