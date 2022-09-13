package example.api

import io.circe.generic.JsonCodec

trait RpcApi[F[_]] {
  def listMeetings: F[List[String]]
  def createMeeting: F[String]
  def joinMeeting(userName: String, meetingId: String): F[String]
  def join(string: String): F[JoinInfo]
}

@JsonCodec case class JoinInfo(meeting: String, Attendee: String)
