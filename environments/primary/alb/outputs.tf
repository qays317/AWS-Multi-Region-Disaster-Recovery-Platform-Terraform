output "alb_dns_name" {                                    
    value = module.alb.alb_dns_name
}

output "alb_zone_id" {
    value = module.alb.alb_zone_id
}

output "target_group_arn" {
    value = module.alb.target_group_arn
}


//---------------------------------------------------
// For CloudWatch alarm 
//---------------------------------------------------
output "target_group_arn_suffix" {
    value = module.alb.target_group_arn_suffix
}
output "alb_arn_suffix" {
    value = module.alb.alb_arn_suffix
}

