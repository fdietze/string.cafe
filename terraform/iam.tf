resource "aws_iam_policy" "chime_admin" {
  name   = "${local.name_prefix}-chime-admin"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "chime:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_http_rpc_chime" {
  role       = module.string_cafe.http_rpc_role.name
  policy_arn = aws_iam_policy.chime_admin.arn
}

resource "aws_iam_role_policy_attachment" "meeting_event_handler_backend" {
  role       = module.meeting_event_handler.role.name
  policy_arn = module.string_cafe.backend_policy_arn
}

resource "aws_iam_role_policy_attachment" "meeting_event_handler_chime" {
  role       = module.meeting_event_handler.role.name
  policy_arn = aws_iam_policy.chime_admin.arn
}
