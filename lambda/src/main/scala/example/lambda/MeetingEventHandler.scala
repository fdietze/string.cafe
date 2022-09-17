package example.lambda

import scala.scalajs.js

object MeetingEventHandler {
  type Type = js.Function2[js.Object, js.Object, js.Promise[Unit]]

  val handle: Type = { (a, b) =>
    js.Dynamic.global.console.log("Event", a, b)

    js.Promise.resolve[Unit](())
  }

}
