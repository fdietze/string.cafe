resource "aws_sns_topic" "meeting_events" {
  name = "${local.name_prefix}-chime-meeting-events"
}
