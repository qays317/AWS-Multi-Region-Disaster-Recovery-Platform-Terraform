
locals {
    az_map = {
        "A" = data.aws_availability_zones.available.names[0]
        "B" = data.aws_availability_zones.available.names[1]
    }

    subnet_config = {
        Pub-A = {
            cidr_block = "172.16.0.0/20"
            availability_zone = local.az_map["A"]
            map_public_ip_on_launch = true
        }
        Pub-B = {
            cidr_block = "172.16.16.0/20"
            availability_zone = local.az_map["B"]
            map_public_ip_on_launch = true
        }
        Prv-A = {
            cidr_block = "172.16.48.0/20"
            availability_zone = local.az_map["A"]
            map_public_ip_on_launch = false
        }
        Prv-B = {
            cidr_block = "172.16.64.0/20"
            availability_zone = local.az_map["B"]
            map_public_ip_on_launch = false
        }
    }
    
    vpc_endpoints_config = {
        "secretsmanager" = {
            type = "Interface"
            security_group_id = module.sg.secretsmanager_endpoint_sg_id
        }
        "logs" = {
            type = "Interface"
            security_group_id = module.sg.vpc_endpoints_sg_id
        }
        "s3" = {
            type = "Gateway"
        } 
        "ecs" = {
            type = "Interface"
            security_group_id = module.sg.vpc_endpoints_sg_id
        }
        "sts" = {
            type = "Interface"
            security_group_id = module.sg.vpc_endpoints_sg_id
        } 
        "monitoring" = {
            type = "Interface"
            security_group_id = module.sg.vpc_endpoints_sg_id
        }
        "ecr.api" = {
            type = "Interface"
            security_group_id = module.sg.vpc_endpoints_sg_id
        }
        "ecr.dkr" = {
            type = "Interface"
            security_group_id = module.sg.vpc_endpoints_sg_id
        }
        "ssmmessages" = {
            type = "Interface"
            security_group_id = module.sg.vpc_endpoints_sg_id
        }
        "ssm" = {
            type = "Interface"
            security_group_id = module.sg.vpc_endpoints_sg_id
        }
        "ec2messages" = {
            type = "Interface"
            security_group_id = module.sg.vpc_endpoints_sg_id
        }
}  
}
