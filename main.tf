#IAM role para la Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Políticas del IAM role
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "sns:Publish",
        Effect   = "Allow",
        Resource = aws_sns_topic.sns_topic.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "index.py"
  output_path = "payload.zip"
}

#Lambda function
resource "aws_lambda_function" "this" {

  function_name    = var.function_name
  handler          = "index.lambda_handler"
  runtime          = var.runtime
  filename         = "payload.zip"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  description      = var.description
  memory_size      = var.memory_size
  timeout          = "30"

  dynamic "environment" {
    for_each = [merge({ sns_topic_arn = aws_sns_topic.sns_topic.arn }, var.function_env)]
    content {
      variables = environment.value
    }
  }

  lifecycle {
    ignore_changes = [
      handler,
      environment,
      runtime
    ]
  }

}

#API Gateway
data "template_file" "apigw_oas" {
  template = file("${path.module}/openapi-template.json")

  vars = {
    lambda_arn = aws_lambda_function.this.arn
  }
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = var.api_name
  description = var.api_description
  body        = data.template_file.apigw_oas.rendered
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on  = [aws_api_gateway_rest_api.api_gateway]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
}

resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = "test"
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "web_acl" {
  name        = "rate-based-example"
  description = "Example of a Cloudfront rate based statement."
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"

      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = false
  }
}

# Associate WAF with API Gateway
resource "aws_wafv2_web_acl_association" "web_acl_association" {
  resource_arn = aws_api_gateway_stage.api_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
}


#Cognito
#Autorizador Cognito
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                             = "zulu_authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.api_gateway.id
  type                             = "COGNITO_USER_POOLS"
  provider_arns                    = aws_cognito_user_pool.user_pool
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = "300"
}

#User pool
resource "aws_cognito_user_pool" "user_pool" {
  name                     = "zulu_user_pool"
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  schema {
    name                = "email"
    required            = true
    mutable             = true
    attribute_data_type = "String"
    string_attribute_constraints {
      min_length = "5"
      max_length = "50"
    }
  }
}

#SNS
resource "aws_sns_topic" "sns_topic" {
  name = "zulu_sns"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = "con3rasjf@gmail.com"
}