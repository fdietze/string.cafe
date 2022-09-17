resource "aws_sns_topic" "meeting_events" {
  provider = aws.us-east-1

  name = "${local.name_prefix}-chime-meeting-events"
}

resource "aws_sns_topic_policy" "meeting_events" {
  provider = aws.us-east-1

  arn = aws_sns_topic.meeting_events.arn

  policy = <<EOF
{
   "Version": "2008-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "chime.amazonaws.com"
        },
        "Action": [
          "sns:Publish"
        ],
        "Resource": "${aws_sns_topic.meeting_events.arn}",
        "Condition": {
          "StringEquals": {
            "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
   ]
}
EOF
}

module "meeting_event_handler" {
  source  = "cornerman/lambda/aws"
  version = "0.1.3"

  name = "${local.name_prefix}-meeting-event-handler"

  source_dir  = "../lambda/target/scala-2.13/scalajs-bundler/main/dist"
  timeout     = 60
  memory_size = 256
  runtime     = "nodejs14.x"
  handler     = "main.meetingEvents"

  environment = merge(module.string_cafe.backend_environment_vars, {
  })
}

resource "aws_sns_topic_subscription" "meeting_event_handler" {
  provider = aws.us-east-1
  topic_arn = aws_sns_topic.meeting_events.arn
  protocol  = "lambda"
  endpoint  = module.meeting_event_handler.function.arn
}

resource "aws_lambda_permission" "meeting_event_handler" {
  action        = "lambda:InvokeFunction"
  function_name = module.meeting_event_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.meeting_events.arn
}
