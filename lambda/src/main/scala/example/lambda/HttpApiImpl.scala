package example.lambda

import cats.effect.IO
import example.api.HttpApi
import funstack.lambda.apigateway.Request

import scala.annotation.unused

class HttpApiImpl(@unused request: Request) {
  val booksListingImpl = HttpApi.booksListing.serverLogic[IO] { case (_, _) =>
    // val userId = request.auth.map(_.sub)
    // val userAttrs = userId.traverse(Fun.auth.getUser(_))
    IO.pure(Right(List(HttpApi.Book("Programming in Scala"))))
  }

  val endpoints = List(
    booksListingImpl,
  )
}
