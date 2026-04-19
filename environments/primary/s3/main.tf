//==================================================================================
//    S3
//==================================================================================


data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/primary/network/terraform.tfstate"
    region = var.state_bucket_region
  }
}

module "s3" {
    source = "../../../modules/s3"
    
    s3_bucket_name = var.s3_bucket_name

    cloudfront_distribution_arn = var.cloudfront_distribution_arn
    ecs_task_role_arn = var.ecs_task_role_arn
    s3_vpc_endpoint_id = data.terraform_remote_state.network.outputs.s3_vpc_endpoint_id
}
