package example.webapp

import colibri.Cancelable
import colibri.reactive._
import org.scalajs.dom
import org.scalajs.dom.{console, document, HTMLAudioElement, HTMLVideoElement}
import outwatch._
import outwatch.dsl._
import typings.amazonChimeSdkJs.audioVideoObserverMod.AudioVideoObserver
import typings.amazonChimeSdkJs.{defaultMeetingSessionMod, meetingSessionConfigurationMod}
import typings.amazonChimeSdkJs.mod.{ConsoleLogger, DefaultDeviceController, DefaultMeetingSession, LogLevel}

import scala.scalajs.js
import scala.scalajs.js.annotation.{JSGlobal, JSImport}
import org.scalajs.macrotaskexecutor.MacrotaskExecutor.Implicits.global

@JSImport("amazon-chime-sdk-js", "DefaultMeetingSession")
@js.native
class MyDefaultMeetingSession extends js.Object {
  def this(
    configuration: js.Any,
    logger: js.Any,
    deviceController: js.Any,
  ) = this()
}

@js.native
@JSGlobal
class JitsiMeetExternalAPI(domain: String, options: js.Object) extends js.Object {
  // https://jitsi.github.io/handbook/docs/dev-guide/dev-guide-iframe/#creating-the-jitsi-meet-api-object
  def dispose(): Unit                                    = js.native
  def getNumberOfParticipants(): Int                     = js.native
  def executeCommand(command: String, arg: String): Unit = js.native
}

object App {

  val logger = new ConsoleLogger(
    "ChimeMeetingLogs",
    // LogLevel.INFO,
  );
  val deviceController = new DefaultDeviceController(logger);

  def createMeeting(audioElement: HTMLAudioElement, meeting: js.Dynamic, attendee: js.Dynamic) = {
    console.log("DU DEV", deviceController)

    // val meetingId      = data.Info.Meeting.Meeting.MeetingId;
    // if (isMeetingHost) {
    //  document.getElementById("meeting-link").innerText = window.location.href + "?meetingId=" + meetingId;
    // }

    console.log(meeting, attendee)

    val configuration = new meetingSessionConfigurationMod.default(
      meeting,
      attendee,
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

  def videoCallRender(meeting: js.Dynamic, attendee: js.Dynamic) = div(
    idAttr := "video-list",
    "VIDEO TILES",
    audio(
      onDomMount.mapFuture { audioElement =>
        try {

          createMeeting(audioElement.asInstanceOf[HTMLAudioElement], meeting, attendee)
        } catch { case t: Throwable => t.printStackTrace(); throw t }
      }.discard,
    ),
  )

  val currentMeeting = Var(Option.empty[String])

  def layout = {
    div(
      Owned[VModifier] {
        currentMeeting.map[VModifier] {
          case None =>
            val listMeetings = HttpRpcClient.api.listMeetings
            div(
              button(
                "Create Meeting",
                cls := "btn btn-small",
                onClick.doEffect(HttpRpcClient.api.createMeeting.void),
              ),
              listMeetings.map { meetingsJson =>
                meetingsJson.map { meetingJson =>
                  div(
                    s"Meeting: ${js.JSON.parse(meetingJson).MeetingId}",
                    button(
                      "Join",
                      cls := "btn btn-small",
                      onClick.as(Some(meetingJson)) --> currentMeeting,
                    ),
                  )
                }
              },
            )
          case Some(meetingJson) =>
            val meeting = js.JSON.parse(meetingJson)
            val getAttendee = HttpRpcClient.api
              .joinMeeting(util.Random.alphanumeric.take(5).mkString, meeting.MeetingId.asInstanceOf[String])
            getAttendee.map { attendeeJson =>
              val attendee = js.JSON.parse(attendeeJson)

              videoCallRender(meeting, attendee)
            }
        }
      },
    )
  }

  def jitsiRoom(roomName: String, language: String, subject: String) = {
    div(
      VModifier.managedElement.asHtml { elem =>
        val domain = "meet.jit.si"
        val options = js.Dynamic.literal(
          roomName = roomName,
          width = 700,
          height = 700,
          parentNode = elem,
          lang = language,
        )
        val api = new JitsiMeetExternalAPI(domain, options)
        api.executeCommand("localSubject", subject);

        Cancelable(() => api.dispose())
      },
    )
  }

}
