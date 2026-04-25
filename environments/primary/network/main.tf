module "network" {
  source = "../../../modules/vpc"
  vpc = var.vpc_config
  subnet = local.subnet_config
  route_table = var.route_table_config
}

module "sg" {
  source = "../../../modules/sg"
  vpc_id = module.network.vpc_id
  vpc_cidr = module.network.vpc_cidr
  security_group = var.security_group_config
  stage_tag = "Network" 
}

module "endpoint" {
  source = "../../../modules/endpoint"
  vpc_id = module.network.vpc_id
  private_subnets_ids = module.network.private_subnets_ids
  vpc_endpoints = local.vpc_endpoints_config 
  private_route_table_id = module.network.private_route_table_id
}

