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

resource "aws_iam_policy" "meeting_event_handler" {
  name   = "${local.name_prefix}-meeting-event-handler"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "meeting_event_handler" {
  role       = module.meeting_event_handler.role.name
  policy_arn = aws_iam_policy.meeting_event_handler.arn
}
