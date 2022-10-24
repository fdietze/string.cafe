package example.api

import io.circe.generic.JsonCodec

trait RpcApi[F[_]] {
  def join(string: String): F[JoinInfo]
}

@JsonCodec case class JoinInfo(Meeting: Meeting, Attendee: Attendee)
@JsonCodec case class Meeting(MeetingId: String, MediaPlacement: MediaPlacement)
@JsonCodec case class MediaPlacement(
  AudioHostUrl: String,
  ScreenDataUrl: String,
  ScreenSharingUrl: String,
  ScreenViewingUrl: String,
  SignalingUrl: String,
  TurnControlUrl: String,
)

@JsonCodec case class Attendee(
  ExternalUserId: String,
  AttendeeId: String,
  JoinToken: String,
)
