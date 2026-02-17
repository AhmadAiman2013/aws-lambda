// 1.0 IAM Role for Lambda deployment

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["2b18947a6a9fc7764fd8b5fb18a863b0c6dac24f"]
}

data "aws_iam_policy_document" "lambda" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type = "AWS"
    }
    condition {
      test     = "StringLike"
      values = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/*"]
      variable = "aws:PrincipalArn"
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      identifiers = [aws_iam_openid_connect_provider.github.arn]
      type = "Federated"
    }
    condition {
      test     = "StringEquals"
      values = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = ["repo:AhmadAiman2013/aws-lambda:*"]
    }
  }

}

resource "aws_iam_role" "lambda_deployer" {
  assume_role_policy = data.aws_iam_policy_document.lambda.json
  name               = "lambda_deployer"
}

// 2.0 IAM Policy for Lambda deployment
data "aws_iam_policy_document" "lambda_deploy_policy" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "lambda:GetFunction",
      "lambda:GetLayerVersion",
      "lambda:CreateFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:PublishVersion",
      "lambda:TagResource",
    ]
    resources = ["arn:aws:lambda:ap-southeast-1:${data.aws_caller_identity.current.account_id}:function:aws-lambda"]
  }

    statement {
        effect = "Allow"
        actions = [
        "iam:PassRole"
        ]
        resources = [aws_iam_role.lambda_execution_role.arn]
    }
}

resource "aws_iam_role_policy" "lambda_deploy_policy" {
  name = "aws-lambda-deploy-policy"
  role = aws_iam_role.lambda_deployer.id
  policy = data.aws_iam_policy_document.lambda_deploy_policy.json
}

// 3.0 Lambda Execution Role
data "aws_iam_policy_document" "lambda_execution" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution.json
}

## Lambda function
resource "aws_lambda_function" "aws_lambda" {
  function_name = "aws-lambda"
  role          = aws_iam_role.lambda_execution_role.arn
  handler = "bootstrap"
  runtime = "provided.al2023"
  package_type = "Zip"

  filename = "${path.module}/bootstrap.zip"


  environment {
    variables = {
      RUST_BACKTRACE = "1"
    }
  }

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
    ]
  }
}

# 4.0 API Gateway for Lambda
resource "aws_apigatewayv2_api" "http_api" {
  name          = "aws-lambda-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  name          = "$default"
  auto_deploy = true
  api_id        = aws_apigatewayv2_api.http_api.id
  default_route_settings {
    throttling_burst_limit = 5
    throttling_rate_limit  = 2
  }
}

# 5.0 API Gateway Integration with Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.aws_lambda.invoke_arn
  payload_format_version = "2.0"
}

# 6.0 API Gateway Route
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 7.0 Lambda Permission for API Gateway
resource "aws_lambda_permission" "apigw_lambda" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.aws_lambda.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}


