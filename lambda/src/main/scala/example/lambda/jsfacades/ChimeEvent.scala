package example.lambda.jsfacades

import scala.scalajs.js
import scala.scalajs.js.annotation.JSName

// https://docs.aws.amazon.com/chime-sdk/latest/dg/using-events.html

@js.native
trait ChimeEvent extends js.Object {
  def version: String                           = js.native
  def source: String                            = js.native
  def account: String                           = js.native
  def id: String                                = js.native
  def region: String                            = js.native
  @JSName("detail-type") def detailType: String = js.native
  def resources: js.Array[js.Any /*TODO*/ ]     = js.native
  def detail: ChimeEventDetail                  = js.native
}

@js.native
trait ChimeEventDetail extends js.Object {
  def version: String     = js.native
  def mediaRegion: String = js.native
  def eventType: String   = js.native
  def timestamp: Int      = js.native

  def meetingId: String         = js.native
  def externalMeetingId: String = js.native

  // only available with attendee events
  def attendeeId: js.UndefOr[String]     = js.native
  def externalUserId: js.UndefOr[String] = js.native
  def networkType: js.UndefOr[String]    = js.native
}
