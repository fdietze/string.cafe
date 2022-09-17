package example.lambda

import cats.effect.IO
import example.api.{JoinInfo, RpcApi}
import facade.amazonaws.AWSConfig
import facade.amazonaws.services.chime.{
  Chime,
  CreateAttendeeRequest,
  CreateMeetingRequest,
  ListMeetingsRequest,
  MeetingNotificationConfiguration,
}
import funstack.backend.Fun
import funstack.lambda.apigateway

import java.util.UUID
import scala.annotation.unused
import scala.scalajs.js
import scala.scalajs.js.JSConverters._

object RpcApiImpl {
  private val chime = new Chime(AWSConfig.apply(region = "us-east-1"))
}

class RpcApiImpl(@unused request: apigateway.Request) extends RpcApi[IO] {
  import RpcApiImpl._

  def listMeetings = {
    val meetings = IO.fromFuture(IO(chime.listMeetingsFuture(ListMeetingsRequest())))

    meetings.map(_.Meetings.get.map(meeting => js.JSON.stringify(meeting)).toList)
  }

  def createMeeting = {
    val request = CreateMeetingRequest(
      null,
      ExternalMeetingId = UUID.randomUUID().toString,
      NotificationsConfiguration = MeetingNotificationConfiguration(
        SnsTopicArn = Fun.config.environment.get("SNS_CHIME_TOPIC_ARN").orUndefined,
      ),
    )
    val meeting = IO.fromFuture(IO(chime.createMeetingFuture(request)))

    meeting.map(response => js.JSON.stringify(response.Meeting.get))
  }

  def joinMeeting(userName: String, meetingId: String) = {
    val attendee = IO.fromFuture(
      IO(
        chime.createAttendeeFuture(
          CreateAttendeeRequest(
            ExternalUserId = userName,
            MeetingId = meetingId,
          ),
        ),
      ),
    )

    attendee.map(response => js.JSON.stringify(response.Attendee.get))
  }

  override def join(string: String): IO[JoinInfo] = {
    // is there a meeting with same string that has a free spot?
    // if yes: add attendee, return meeting + attendee
    // else: create new meeting, return meeting + attendee
    ???
  }
}
