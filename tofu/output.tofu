output "deployer_role_arn" {
  value = aws_iam_role.lambda_deployer.arn
}

output "api_endpoint" {
  value = aws_apigatewayv2_stage.default.invoke_url
}