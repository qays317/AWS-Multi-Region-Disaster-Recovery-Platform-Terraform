# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "main" {
  for_each = var.function
  name = "/aws/lambda/${var.name_prefix}/${each.key}"
  retention_in_days = 7
  tags       = {
    Name = each.key
  }
}

data "archive_file" "main" {
  for_each = var.function
  type = "zip"
  source_dir = "${var.lambda_source_base}/${each.key}"
  output_path = "${path.module}/build/${each.key}.zip"
}

resource "aws_lambda_function" "main" {
  for_each = var.function
  function_name = each.key
  role          = each.value.role_arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = each.value.timeout

  filename         = data.archive_file.main[each.key].output_path

  source_code_hash = data.archive_file.main[each.key].output_base64sha256

  layers = each.key == "validate-db-writable" ? [aws_lambda_layer_version.pymysql.arn] : []

  dynamic "vpc_config" {
    for_each = try(each.value.vpc_config, null) == null ? [] : [each.value.vpc_config]
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  environment {
    variables = each.value.environment
  }

  depends_on = [aws_cloudwatch_log_group.main]
  tags       = {
    Name = each.key
  }
}



resource "aws_lambda_layer_version" "pymysql" {
  filename   = "../../lambdas/pymysql-layer.zip"
  layer_name = "pymysql-layer"

  compatible_runtimes = ["python3.12"]
}
