resource "aws_cloudwatch_log_group" "main" {
  for_each = local.checks
  name = "/aws/lambda/${local.name_prefix}-${each.key}"
  retention_in_days = 7
  tags = local.common_tags
}

/*
resource "aws_cloudwatch_log_group" "lambda_recheck_incident" {
  name              = "/aws/lambda/${local.name_prefix}-recheck-incident"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_check_replica_readiness" {
  name              = "/aws/lambda/${local.name_prefix}-check-replica-readiness"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_promote_replica" {
  name              = "/aws/lambda/${local.name_prefix}-promote-replica"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_check_db_available" {
  name              = "/aws/lambda/${local.name_prefix}-check-db-available"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_validate_db_writable" {
  name              = "/aws/lambda/${local.name_prefix}-validate-db-writable"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_scaleup_dr_service" {
  name              = "/aws/lambda/${local.name_prefix}-scaleup-dr-service"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_check_ecs_healthy" {
  name              = "/aws/lambda/${local.name_prefix}-check-ecs-healthy"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_validate_application" {
  name              = "/aws/lambda/${local.name_prefix}-validate-application"
  retention_in_days = 7
  tags              = local.common_tags
}
*/


data "archive_file" "main" {
  for_each = local.checks
  type = "zip"
  source_dir = "${local.lambda_source_base}/${each.key}"
  output_path = "${path.module}/build/${each.key}.zip"
}

/*
data "archive_file" "recheck_incident_zip" {
  type        = "zip"
  source_dir  = "${local.lambda_source_base}/recheck-incident"
  output_path = "${path.module}/build/recheck-incident.zip"
}

data "archive_file" "check_replica_readiness_zip" {
  type        = "zip"
  source_dir  = "${local.lambda_source_base}/check-replica-readiness"
  output_path = "${path.module}/build/check-replica-readiness.zip"
}

data "archive_file" "promote_replica_zip" {
  type        = "zip"
  source_dir  = "${local.lambda_source_base}/promote-replica"
  output_path = "${path.module}/build/promote-replica.zip"
}

data "archive_file" "check_db_available_zip" {
  type        = "zip"
  source_dir  = "${local.lambda_source_base}/check-db-available"
  output_path = "${path.module}/build/check-db-available.zip"
}

data "archive_file" "validate_db_writable_zip" {
  type        = "zip"
  source_dir  = "${local.lambda_source_base}/validate-db-writable"
  output_path = "${path.module}/build/validate-db-writable.zip"
}

data "archive_file" "scaleup_dr_service_zip" {
  type        = "zip"
  source_dir  = "${local.lambda_source_base}/scaleup-dr-service"
  output_path = "${path.module}/build/scaleup-dr-service.zip"
}

data "archive_file" "check_ecs_healthy_zip" {
  type        = "zip"
  source_dir  = "${local.lambda_source_base}/check-ecs-healthy"
  output_path = "${path.module}/build/check-ecs-healthy.zip"
}

data "archive_file" "validate_application_zip" {
  type        = "zip"
  source_dir  = "${local.lambda_source_base}/validate-application"
  output_path = "${path.module}/build/validate-application.zip"
}
*/


resource "aws_lambda_function" "main" {
  for_each = local.checks
  function_name = "${local.name_prefix}-${each.key}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = each.value.timeout

  filename         = data.archive_file.main[each.key].output_path
  source_code_hash = data.archive_file.main[each.key].output_base64sha256

  environment {
    variables = each.value.environment
  }

  depends_on = [aws_cloudwatch_log_group.main]
  tags       = local.common_tags
}
/*

resource "aws_lambda_function" "recheck_incident" {
  function_name = "${local.name_prefix}-recheck-incident"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  filename         = data.archive_file.recheck_incident_zip.output_path
  source_code_hash = data.archive_file.recheck_incident_zip.output_base64sha256

  environment {
    variables = {
      PRIMARY_ALARM_NAME = var.primary_alarm_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_recheck_incident]
  tags       = local.common_tags
}

resource "aws_lambda_function" "check_replica_readiness" {
  function_name = "${local.name_prefix}-check-replica-readiness"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename         = data.archive_file.check_replica_readiness_zip.output_path
  source_code_hash = data.archive_file.check_replica_readiness_zip.output_base64sha256

  environment {
    variables = {
      DR_REGION                   = var.dr_region
      DR_REPLICA_IDENTIFIER       = var.dr_replica_identifier
      MAX_REPLICATION_LAG_SECONDS = tostring(var.max_replication_lag_seconds)
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_check_replica_readiness]
  tags       = local.common_tags
}

resource "aws_lambda_function" "promote_replica" {
  function_name = "${local.name_prefix}-promote-replica"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename         = data.archive_file.promote_replica_zip.output_path
  source_code_hash = data.archive_file.promote_replica_zip.output_base64sha256

  environment {
    variables = {
      DR_REGION             = var.dr_region
      DR_REPLICA_IDENTIFIER = var.dr_replica_identifier
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_promote_replica]
  tags       = local.common_tags
}

resource "aws_lambda_function" "check_db_available" {
  function_name = "${local.name_prefix}-check-db-available"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename         = data.archive_file.check_db_available_zip.output_path
  source_code_hash = data.archive_file.check_db_available_zip.output_base64sha256

  environment {
    variables = {
      DR_REGION             = var.dr_region
      DR_REPLICA_IDENTIFIER = var.dr_replica_identifier
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_check_db_available]
  tags       = local.common_tags
}

resource "aws_lambda_function" "validate_db_writable" {
  function_name = "${local.name_prefix}-validate-db-writable"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename         = data.archive_file.validate_db_writable_zip.output_path
  source_code_hash = data.archive_file.validate_db_writable_zip.output_base64sha256

  environment {
    variables = {
      DB_HOST            = var.db_host
      DB_PORT            = tostring(var.db_port)
      DB_NAME            = var.db_name
      DB_USER            = var.db_user
      DB_PASSWORD        = var.db_password
      DB_CONNECT_TIMEOUT = tostring(var.db_connect_timeout)
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_validate_db_writable]
  tags       = local.common_tags
}

resource "aws_lambda_function" "scaleup_dr_service" {
  function_name = "${local.name_prefix}-scaleup-dr-service"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename         = data.archive_file.scaleup_dr_service_zip.output_path
  source_code_hash = data.archive_file.scaleup_dr_service_zip.output_base64sha256

  environment {
    variables = {
      DR_REGION        = var.dr_region
      ECS_CLUSTER_NAME = var.ecs_cluster_name
      ECS_SERVICE_NAME = var.ecs_service_name
      DR_DESIRED_COUNT = tostring(var.dr_desired_count)
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_scaleup_dr_service]
  tags       = local.common_tags
}

resource "aws_lambda_function" "check_ecs_healthy" {
  function_name = "${local.name_prefix}-check-ecs-healthy"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  filename         = data.archive_file.check_ecs_healthy_zip.output_path
  source_code_hash = data.archive_file.check_ecs_healthy_zip.output_base64sha256

  environment {
    variables = {
      DR_REGION        = var.dr_region
      ECS_CLUSTER_NAME = var.ecs_cluster_name
      ECS_SERVICE_NAME = var.ecs_service_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_check_ecs_healthy]
  tags       = local.common_tags
}

resource "aws_lambda_function" "validate_application" {
  function_name = "${local.name_prefix}-validate-application"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  filename         = data.archive_file.validate_application_zip.output_path
  source_code_hash = data.archive_file.validate_application_zip.output_base64sha256

  environment {
    variables = {
      APP_HEALTHCHECK_URL     = var.app_healthcheck_url
      APP_HEALTHCHECK_TIMEOUT = tostring(var.app_healthcheck_timeout)
      EXPECTED_STATUS_CODE    = tostring(var.expected_status_code)
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_validate_application]
  tags       = local.common_tags
}*/