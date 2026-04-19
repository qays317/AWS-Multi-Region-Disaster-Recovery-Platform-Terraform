output "vpc_id" {
    value = module.network.vpc_id
}

output "vpc_cidr" {
    value = module.network.vpc_cidr
}

output "subnets" {
    value = module.network.subnets
}

output "private_subnets_ids" {
    value = module.network.private_subnets_ids
}

output "public_subnets_ids" {
    value = module.network.public_subnets_ids
}




output "rds_sg_id" {
    value = module.sg.rds_sg_id
}

output "db_setup_lambda_sg_id" {
    value = module.sg.db_setup_lambda_sg_id  
}

output "secretsmanager_endpoint_sg_id" {
    value = module.sg.secretsmanager_endpoint_sg_id
}

output "alb_sg_id" {
    value = module.sg.alb_sg_id
}

output "s3_vpc_endpoint_id" {
    value = module.endpoint.s3_vpc_endpoint_id
}

output "wordpress_service_sg_id" {
    value = module.sg.wordpress_service_sg_id
  
}
