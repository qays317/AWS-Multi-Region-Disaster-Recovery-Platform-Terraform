# Get private route table for Gateway endpoints
data "aws_route_tables" "private" {
  vpc_id = var.vpc_id
  filter {
    name = "tag:Name"
    values = ["*private*", "*Private*"]
  }
}

data "aws_region" "current" {}

# VPC Endpoints
resource "aws_vpc_endpoint" "main" {
  for_each = var.vpc_endpoints
    vpc_id = var.vpc_id
    service_name = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
    vpc_endpoint_type = each.value.type
    # Interface endpoints use subnets and security groups
    subnet_ids = each.value.type == "Interface" ? var.private_subnets_ids : null
    security_group_ids = each.value.type == "Interface" ? [each.value.security_group_id] : null
    private_dns_enabled = each.value.type == "Interface" ? true : null
    # Gateway endpoints use route tables
    route_table_ids = each.value.type == "Gateway" ? data.aws_route_tables.private.ids : null
    # Tag
    tags = { Name = "${each.key}-endpoint" }
}


