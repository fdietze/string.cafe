package example.lambda

import example.api.{EventApi, HttpApi}
import funstack.lambda.apigateway.{Handler, Request}
import funstack.backend.Fun
import sloth.Client
import cats.effect.IO
import chameleon.ext.circe._

class HttpApiImpl(request: Request) {
  private val client     = Client.contra(Fun.ws.sendTransportFunction[String])
  private val streamsApi = client.wire[EventApi[* => IO[Unit]]]

  val booksListingImpl = HttpApi.booksListing.serverLogic[IO] { case (_, _) =>
    val userId = request.auth.map(_.sub)
    // val userAttrs = userId.traverse(Fun.auth.getUser(_))

    val sendEvent = streamsApi.myMessages.apply(s"HttpApi Request by ${userId}!")
    val response  = IO.pure(Right(List(HttpApi.Book("Programming in Scala"))))

    sendEvent *> response
  }

  val endpoints = List(
    booksListingImpl,
  )
}
