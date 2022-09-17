resource "aws_sns_topic" "meeting_events" {
  name = "${local.name_prefix}-chime-meeting-events"
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

  # environment = {
  # }
}

resource "aws_sns_topic_subscription" "meeting_event_handler" {
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
