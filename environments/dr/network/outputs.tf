output "vpc_id" {
    value = module.network.vpc_id
}

output "vpc_cidr" {
    value = module.network.vpc_cidr
}

output "public_subnets_ids" {
    value = module.network.public_subnets_ids
}

output "private_subnets_ids" {
    value = module.network.private_subnets_ids
}





output "secretsmanager_endpoint_sg_id" {
    value = module.sg.secretsmanager_endpoint_sg_id
}

output "alb_sg_id" {
    value = module.sg.alb_sg_id
}

output "wordpress_service_sg_id" {
    value = module.sg.wordpress_service_sg_id
  
}
