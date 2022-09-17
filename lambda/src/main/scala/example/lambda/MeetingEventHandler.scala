package example.lambda

import net.exoego.facade.aws_lambda.{Context, SNSEvent}

import scala.scalajs.js

object MeetingEventHandler {
  type Type = js.Function2[SNSEvent, Context, js.Promise[Unit]]

  val handle: Type = { (event, context) =>
    js.Dynamic.global.console.log("Event", event, context)

    val handlers = event.Records.map { record =>
      js.Dynamic.global.console.log("Record", record)
      js.Promise.resolve[Unit](())
    }

    js.Promise.all(handlers).`then`[Unit](_ => ())
  }

}
