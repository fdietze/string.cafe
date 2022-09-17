package example.api

trait EventApi[F[_]] {
  def meetingStarted: F[String]
  def meetingIdEnded: F[String]
}
