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

  alarm_actions = []

  tags = {
    Name = "wordpress-failover-composite-alarm"
  }
}



/*
===================================================================================================================================================================
===================================================================================================================================================================
                                                              EventBridge Rule
===================================================================================================================================================================
===================================================================================================================================================================
*/

resource "aws_cloudwatch_event_rule" "failover_alarm_rule" {
  name        = "wordpress-failover-alarm-rule"
  description = "Start DR Step Function when composite failover alarm enters ALARM state"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    resources   = [aws_cloudwatch_composite_alarm.failover_trigger_alarm.arn]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })
}


/*
===================================================================================================================================================================
===================================================================================================================================================================
                                                             SFN IAM
===================================================================================================================================================================
===================================================================================================================================================================
*/

data "terraform_remote_state" "sfn" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/operations/dr_orchestration/terraform.tfstate"
    region = var.state_bucket_region
  }
}

data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eventbridge_invoke_sfn_role" {
  name               = "eventbridge-start-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role.json
}

data "aws_iam_policy_document" "eventbridge_start_sfn_policy" {
  statement {
    effect = "Allow"

    actions = ["states:StartExecution"]

    resources = [
      data.terraform_remote_state.sfn.outputs.state_machine_arn 
    ]
  }
}

resource "aws_iam_policy" "eventbridge_start_sfn_policy" {
  name   = "eventbridge-start-sfn-policy"
  policy = data.aws_iam_policy_document.eventbridge_start_sfn_policy.json
}

resource "aws_iam_role_policy_attachment" "eventbridge_start_sfn_attach" {
  role       = aws_iam_role.eventbridge_invoke_sfn_role.name
  policy_arn = aws_iam_policy.eventbridge_start_sfn_policy.arn
}



resource "aws_cloudwatch_event_target" "start_failover_sfn" {
  rule      = aws_cloudwatch_event_rule.failover_alarm_rule.name
  arn       = data.terraform_remote_state.sfn.outputs.state_machine_arn 
  role_arn  = aws_iam_role.eventbridge_invoke_sfn_role.arn

  input_transformer {
    input_paths = {
      alarm_name   = "$.detail.alarmName"
      state_value  = "$.detail.state.value"
      reason       = "$.detail.state.reason"
      account      = "$.account"
      region       = "$.region"
      time         = "$.time"
    }

    input_template = <<EOF
{
  "trigger_source": "eventbridge-cloudwatch-alarm",
  "alarm_name": <alarm_name>,
  "alarm_state": <state_value>,
  "alarm_reason": <reason>,
  "account": <account>,
  "region": <region>,
  "time": <time>
}
EOF
  }
}

