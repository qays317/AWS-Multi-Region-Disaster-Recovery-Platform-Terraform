output "s3_vpc_endpoint_id" {
    value = module.ecs.s3_vpc_endpoint_id
}

output "ecs_cluster_name" {
    value = var.ecs_cluster_name_config
}
