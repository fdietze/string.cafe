package example.lambda

import example.api.EventApi
import funstack.lambda.ws.eventauthorizer.{Handler, Message}

import scala.annotation.unused

class EventApiAuthImpl(@unused request: Message) extends EventApi[Handler.IOFunc1] {
  def meetingStarted: Handler.IOFunc1[String] = { _ =>
    // cats.effect.IO.pure(request.auth.isDefined)
    cats.effect.IO.pure(true)
  }
  def meetingIdEnded: Handler.IOFunc1[String] = { _ =>
    // cats.effect.IO.pure(request.auth.isDefined)
    cats.effect.IO.pure(true)
  }
}
