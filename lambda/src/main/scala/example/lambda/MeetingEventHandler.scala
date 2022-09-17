package example.lambda

import cats.effect.IO
import cats.implicits._
import chameleon.{Deserializer, Serializer, SerializerDeserializer}
import example.api.EventApi
import example.lambda.jsfacades.ChimeEvent
import facade.amazonaws.AWSConfig
import facade.amazonaws.services.chime.{Chime, GetMeetingRequest}
import funstack.backend.Fun
import net.exoego.facade.aws_lambda.{Context, SNSEvent}
import sloth.Client

import scala.scalajs.js

object MeetingEventHandler {
  import js.Dynamic.{global => g}

  type Type = js.Function2[SNSEvent, Context, js.Promise[Unit]]

  implicit def StringSerializer: SerializerDeserializer[String, String] = new Serializer[String, String]
    with Deserializer[String, String] {
    override def serialize(arg: String): String                      = arg
    override def deserialize(arg: String): Either[Throwable, String] = Right(arg)
  }

  implicit def UnitStringSerializer: SerializerDeserializer[Unit, String] = new Serializer[Unit, String]
    with Deserializer[Unit, String] {
    override def serialize(arg: Unit): String                      = ""
    override def deserialize(arg: String): Either[Throwable, Unit] = Right(())
  }

  private val client       = Client.contra(Fun.ws.sendTransportFunction[String])
  private val eventsSender = client.wire[EventApi[* => IO[Unit]]]

  private lazy val chime = new Chime(AWSConfig.apply(region = "us-east-1"))

  private def getMeeting(meetingId: String) = {
    val meeting = IO.fromFuture(IO(chime.getMeetingFuture(GetMeetingRequest(meetingId))))

    meeting.map(meeting => js.JSON.stringify(meeting.Meeting.get))
  }

  val handle: Type = { (event, context) =>
    g.console.log("Event", event, context)

    val handler = event.Records.toSeq.traverse_ { record =>
      g.console.log("Record", record)

      val message = js.JSON.parse(record.Sns.Message).asInstanceOf[ChimeEvent]

      message.detail.eventType match {
        case "chime:MeetingStarted" =>
          println("meeting start")
          getMeeting(message.detail.meetingId).flatMap(eventsSender.meetingStarted)
        case "chime:MeetingEnded" =>
          println("meeting end")
          eventsSender.meetingIdEnded(message.detail.meetingId)
        case "chime:AttendeeLeft" | "chime:AttendeeDropped" =>
          println("attendee left/dropped meeting")
          IO.unit
        case "chime:AttendeeJoined" =>
          println("attendee joined meeting")
          IO.unit
        case eventType =>
          IO.println(s"Ignore event: ${eventType}")
      }
    }

    handler.unsafeToPromise()(cats.effect.unsafe.IORuntime.global)
  }

}
