package example.lambda

import example.api.EventApi
import funstack.lambda.ws.eventauthorizer.{Handler, Message}

class EventApiAuthImpl(request: Message) extends EventApi[Handler.IOFunc1] {
  def myMessages: Handler.IOFunc1[String] = { event =>
    // cats.effect.IO.pure(request.auth.isDefined)
    cats.effect.IO.pure(true)
  }
}
