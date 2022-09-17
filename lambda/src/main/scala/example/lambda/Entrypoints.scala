package example.lambda

import cats.effect.IO
import example.api.{EventApi, RpcApi}
import funstack.lambda.apigateway.Request
import funstack.lambda.ws.eventauthorizer.Message
import funstack.lambda.{http, ws}
import sloth.Router
import chameleon.ext.circe._

import scala.scalajs.js

object Entrypoints {
  @js.annotation.JSExportTopLevel("httpApi")
  val httpApi = http.api.tapir.Handler.handle { request =>
    new HttpApiImpl(request).endpoints
  }

  @js.annotation.JSExportTopLevel("httpRpc")
  val httpRpc = http.rpc.Handler.handle { request: Request =>
    Router[String, IO](new ApiRequestLogger[IO])
      .route[RpcApi[IO]](new RpcApiImpl(request))
  }

  @js.annotation.JSExportTopLevel("wsRpc")
  val wsRpc = ws.rpc.Handler.handle[String] { request: Request =>
    Router[String, IO](new ApiRequestLogger[IO])
      .route[RpcApi[IO]](new RpcApiImpl(request))
  }

  @js.annotation.JSExportTopLevel("wsEventAuth")
  val wsEventAuth = ws.eventauthorizer.Handler.handleFunc { request: Message =>
    Router
      .contra[String, ws.eventauthorizer.Handler.IOFunc1]
      .route[EventApi[ws.eventauthorizer.Handler.IOFunc1]](new EventApiAuthImpl(request))
  }

  @js.annotation.JSExportTopLevel("meetingEvents")
  val meetingEvents = MeetingEventHandler.handle
}
