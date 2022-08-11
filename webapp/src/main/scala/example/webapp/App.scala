package example.webapp

import colibri.Cancelable
import colibri.reactive._
import formidable._
import org.scalajs.dom
import outwatch._
import outwatch.dsl._
import pt.kcry.sha._
import typings.normalizeUrl.mod.{apply => normalizeUrl}

import scala.scalajs.js
import scala.scalajs.js.annotation.JSGlobal

@js.native
@JSGlobal
class JitsiMeetExternalAPI(domain: String, options: js.Object) extends js.Object {
  // https://jitsi.github.io/handbook/docs/dev-guide/dev-guide-iframe/#creating-the-jitsi-meet-api-object
  def dispose(): Unit                                    = js.native
  def getNumberOfParticipants(): Int                     = js.native
  def executeCommand(command: String, arg: String): Unit = js.native
}

object App {

  sealed trait Language
  object Language                                       {
    case object en extends Language
    case object de extends Language
  }
  case class UrlConfig(url: String, language: Language) {
    def id                       = s"$language:${normalizeUrl(url)}"
    def room(n: Int = 1): String = {
      var current = id
      var i       = 0
      while (i < n) {
        current = hash(current)
        i += 1
      }
      current
    }
  }

  def layout = div(Owned {
    val urlConfig  = Var(UrlConfig("news.ycombinator.com", Language.en))
    val roomNumber = Var(1)

    div(
      Form[UrlConfig].render(urlConfig, formConfig),
      div(urlConfig.map(_.id)),
      div(cls := "font-mono", "room 1: ", urlConfig.map(_.room(1))),
      div(cls := "font-mono", "room 2: ", urlConfig.map(_.room(2))),
      div(cls := "font-mono", "room 3: ", urlConfig.map(_.room(3))),
      urlConfig.observable.debounceMillis(1000).distinctByOnEquals(_.id).combineLatestMap(roomNumber.observable) { (urlConfig, roomNumber) =>
        jitsiRoom(urlConfig.room(roomNumber), urlConfig.language.toString, subject = urlConfig.id)
      },
    ): VModifier
  })

  def jitsiRoom(roomName: String, language: String, subject: String) = {
    div(
      VModifier.managedElement.asHtml { elem =>
        val domain  = "meet.jit.si"
        val options = js.Dynamic.literal(
          roomName = roomName,
          width = 700,
          height = 700,
          parentNode = dom.document.querySelector("#meet"),
          lang = language,
        )
        val api     = new JitsiMeetExternalAPI(domain, options)
        api.executeCommand("localSubject", subject);

        Cancelable(() => api.dispose())
      },
    )
  }

  def hash(str: String): String = {
    Sha2_256.hash(str.getBytes).view.map(byte => f"${byte & 0xff}%02x").mkString
  }

  val formConfig = new FormConfig {
    override def textInput(state: Var[String], inputPlaceholder: String, validationMessage: Rx[Option[String]]): VModifier = Owned {
      div(
        input(
          cls         := "border border-black",
          tpe         := "text",
          placeholder := inputPlaceholder,
          value <-- state,
          onInput.stopPropagation.value --> state,
        ),
        validationMessage.map(_.map(msg => div(msg, color.red))),
      ): VModifier
    }
  }
}
