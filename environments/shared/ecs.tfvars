ecs_security_group_config = {
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

ecs_task_definition_config = {
    family = "wordpress-task"
    cpu = "1024"
    memory = "2048"
    rds_name = "mysql"
}

ecs_service_sg_name = "wordpress-service-SG"

vpc_endpoints_config = {
    "logs" = "Interface",
    "s3" = "Gateway", 
    "ecs" = "Interface",
    "sts" = "Interface",
    "monitoring" = "Interface",
    "ecr.api" = "Interface",
    "ecr.dkr" = "Interface",
    "ssmmessages" = "Interface",
    "ssm" = "Interface",
    "ec2messages" = "Interface",
    "secretsmanager" = "Interface"
}


