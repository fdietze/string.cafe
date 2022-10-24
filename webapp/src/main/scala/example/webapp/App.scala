package example.webapp

import colibri.reactive._
import example.api.JoinInfo
import org.scalajs.dom.{console, document, HTMLAudioElement, HTMLVideoElement}
import org.scalajs.macrotaskexecutor.MacrotaskExecutor.Implicits.global
import outwatch._
import outwatch.dsl._
import typings.amazonChimeSdkJs.audioVideoObserverMod.AudioVideoObserver
import typings.amazonChimeSdkJs.meetingSessionConfigurationMod
import typings.amazonChimeSdkJs.mod.{ConsoleLogger, DefaultDeviceController, DefaultMeetingSession}
import cats.effect.IO

import io.circe._
import io.circe.syntax._

import scala.scalajs.js
import scala.scalajs.js.annotation.JSImport

@JSImport("amazon-chime-sdk-js", "DefaultMeetingSession")
@js.native
class MyDefaultMeetingSession extends js.Object {
  def this(
    configuration: js.Any,
    logger: js.Any,
    deviceController: js.Any,
  ) = this()
}

object App {

  val logger = new ConsoleLogger(
    "ChimeMeetingLogs",
    // LogLevel.INFO,
  );
  val deviceController = new DefaultDeviceController(logger);

  def createMeeting(audioElement: HTMLAudioElement, joinInfo: JoinInfo) = {
    console.log("DU DEV", deviceController)

    // val meetingId      = data.Info.Meeting.Meeting.MeetingId;
    // if (isMeetingHost) {
    //  document.getElementById("meeting-link").innerText = window.location.href + "?meetingId=" + meetingId;
    // }

    console.log(joinInfo)

    val configuration = new meetingSessionConfigurationMod.default(
      js.Dynamic.literal(Meeting = js.JSON.parse(joinInfo.Meeting.asJson.noSpaces)),
      js.Dynamic.literal(Attendee = js.JSON.parse(joinInfo.Attendee.asJson.noSpaces)),
    );

    console.log("HAVE IT", configuration)
    val meetingSession = new MyDefaultMeetingSession(
      configuration,
      logger,
      deviceController,
    ).asInstanceOf[DefaultMeetingSession];
    console.log(meetingSession)

    for {
      audioInputs <- meetingSession.audioVideo.listAudioInputDevices().toFuture
      _            = println("HALLO")
      videoInputs <- meetingSession.audioVideo.listVideoInputDevices().toFuture
      _            = println("WO?")

      _ <- meetingSession.audioVideo
             // .startAudioInput(audioInputs(0).deviceId)
             .asInstanceOf[js.Dynamic]
             .chooseAudioInputDevice(audioInputs(0).deviceId)
             .asInstanceOf[js.Promise[Any]]
             .toFuture

      _ = println("hat audio")
      _ <- meetingSession.audioVideo
             // .startVideoInput(videoInputs(0).deviceId)
             .asInstanceOf[js.Dynamic]
             .chooseVideoInputDevice(videoInputs(0).deviceId)
             .asInstanceOf[js.Promise[Any]]
             .toFuture
      _ = println("casino")
    } yield {
      // videoTileDidUpdate is called whenever a new tile is created or tileState changes.
      val observer = AudioVideoObserver().setVideoTileDidUpdate { tileState =>
        console.log("VIDEO TILE DID UPDATE");
        console.log(tileState);
        // Ignore a tile without attendee ID and other attendee's tile.
        if (tileState.boundAttendeeId != null) {
          updateTiles(meetingSession);
        }
      // }.setAudioVideoDidStop { sessionStatus =>
      // v3
      // meetingSession.audioVideo.stopAudioInput();
      // Or use the destroy API to call stopAudioInput and stopVideoInput.
      // meetingSession.deviceController.destroy();
      }

      meetingSession.audioVideo.addObserver(observer);

      println("LOLITA")
      meetingSession.audioVideo.startLocalVideoTile();

      println("BOUNDING")
      meetingSession.audioVideo.bindAudioElement(audioElement).toFuture.foreach { _ =>
        println("DINGDING")
        meetingSession.audioVideo.start();
      }
    };
  }

  def updateTiles(meetingSession: DefaultMeetingSession) = {
    val tiles = meetingSession.audioVideo.getAllVideoTiles();
    console.log("tiles", tiles);
    tiles.foreach { tile =>
      val tileId            = tile.state().tileId.asInstanceOf[Double]
      val existVideoElement = document.getElementById("video-" + tileId);

      if (existVideoElement == null) {
        val videoElement = document.createElement("video").asInstanceOf[HTMLVideoElement]
        videoElement.id = "video-" + tileId;
        document.getElementById("video-list").append(videoElement);
        meetingSession.audioVideo.bindVideoElement(
          tileId,
          videoElement,
        );
      }
    }
  }

  def videoCallRender(joinInfo: JoinInfo) = div(
    idAttr := "video-list",
    "VIDEO TILES",
    audio(
      onDomMount.mapFuture { audioElement =>
        try {

          createMeeting(audioElement.asInstanceOf[HTMLAudioElement], joinInfo)
        } catch { case t: Throwable => t.printStackTrace(); throw t }
      }.discard,
    ),
  )

  val currentMeeting = Var(Option.empty[JoinInfo])

  def layout = {
    div(
      Owned[VModifier] {
        currentMeeting.map[VModifier] {
          case None =>
            val string = Var("")
            div(
              input(tpe := "text", placeholder := "Your String", onInput.value --> string),
              button(
                "join",
                onClick.asEffect {
                  IO.defer(HttpRpcClient.api.join(string.now())).map(Some(_))
                } --> currentMeeting,
              ),
            )
          case Some(joinInfo) =>
            videoCallRender(joinInfo)
        }
      },
    )
  }
}
