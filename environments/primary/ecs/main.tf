//==================================================================================
// ECS
//==================================================================================

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/primary/network/terraform.tfstate"
    region = var.state_bucket_region
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/primary/rds/terraform.tfstate"
    region = var.state_bucket_region
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/primary/alb/terraform.tfstate"
    region = var.state_bucket_region
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/global/iam/terraform.tfstate"
    region = var.state_bucket_region
  }    
}

data "terraform_remote_state" "cdn_dns" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/global/cdn_dns/terraform.tfstate"
    region = var.state_bucket_region
  }    
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

module "ecs" {
    source = "../../../modules/ecs"
    # infrastructure data
    vpc_id = data.terraform_remote_state.network.outputs.vpc_id    
    private_subnets_ids = data.terraform_remote_state.network.outputs.private_subnets_ids  
    # RDS data     
    wordpress_secret_arn = data.terraform_remote_state.rds.outputs.wordpress_secret_arn
    # ALB data
    target_group_arn = data.terraform_remote_state.alb.outputs.target_group_arn
    # Storage & CDN
    s3_bucket_name = var.primary_media_s3_bucket
    primary_domain = var.primary_domain
    cloudfront_distribution_id = data.terraform_remote_state.cdn_dns.outputs.cloudfront_distribution_id
    cloudfront_distribution_domain = data.terraform_remote_state.cdn_dns.outputs.cloudfront_distribution_domain
    # Docker image
    ecr_image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecs-wordpress-app"
    # ECS configuration
    ecs_cluster_name = var.ecs_cluster_name
    ecs_execution_role_arn = data.terraform_remote_state.iam.outputs.ecs_execution_role_arn
    ecs_task_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_role_arn
    ecs_task_definition = var.ecs_task_definition_config
    ecs_service_name = var.ecs_service_name
    ecs_task_desired_count = var.ecs_task_desired_count
    ecs_service_sg_id = data.terraform_remote_state.network.outputs.wordpress_service_sg_id
}

