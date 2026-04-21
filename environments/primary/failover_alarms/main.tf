data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/primary/alb/terraform.tfstate"
    region = var.state_bucket_region
  }
}


/*
===================================================================================================================================================================
===================================================================================================================================================================
                                                          SNS
===================================================================================================================================================================
===================================================================================================================================================================
*/

resource "aws_sns_topic" "alerts" {
  name = "wordpress-alerts-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol = "email"
  endpoint = var.sns_email
}


/*
===================================================================================================================================================================
===================================================================================================================================================================
                                                           CloudWatch Alarms
===================================================================================================================================================================
===================================================================================================================================================================
*/

# CloudWatch alarm to monitor ECS service health via ALB target group
resource "aws_cloudwatch_metric_alarm" "ecs_health_alarm" {
  alarm_name = "wordpress-health-alarm"
  alarm_description = "Monitor healthy ECS tasks"
  namespace = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"
  statistic = "Average"
  threshold = 2
  comparison_operator = "LessThanThreshold"
  period = 60
  evaluation_periods = 1
  treat_missing_data = "breaching"
  alarm_actions = []

  dimensions = {
    TargetGroup = data.terraform_remote_state.alb.outputs.target_group_arn_suffix 
    LoadBalancer = data.terraform_remote_state.alb.outputs.alb_arn_suffix
  }

  tags = { Name = "wordpress-health-alarm" }
}


resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks_alarm" {
  alarm_name = "wordpress-ecs-running-low"
  alarm_description = "Alarm when ECS running task count is lower than expected"
  namespace = "ECS/ContainerInsights"
  metric_name = "RunningTaskCount"
  statistic = "Average"
  threshold = 2
  comparison_operator = "LessThanThreshold"
  period = 60
  evaluation_periods = 1
  treat_missing_data = "breaching"
  alarm_actions = []

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    Name = "wordpress-ecs-running-low"
  }
}


resource "aws_cloudwatch_composite_alarm" "failover_trigger_alarm" {
  alarm_name = "wordpress-failover-composite-alarm"
  alarm_description = "Trigger failover only when ALB health and ECS running task count both indicate a real incident"

  alarm_rule = join(" AND ", [
    "ALARM(\"${aws_cloudwatch_metric_alarm.ecs_health_alarm.alarm_name}\")",
    "ALARM(\"${aws_cloudwatch_metric_alarm.ecs_running_tasks_alarm.alarm_name}\")"
  ])

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  tags = {
    Name = "wordpress-failover-composite-alarm"
  }
}

