resource "aws_iam_policy" "lambda_http_rpc" {
  name   = "${local.name_prefix}-lambda-http-rpc"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "chime:*",
          "sns:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_http_rpc" {
  role       = module.string_cafe.http_rpc_role.name
  policy_arn = aws_iam_policy.lambda_http_rpc.arn
}
