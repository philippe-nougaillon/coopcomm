import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editor"]

  connect() {
    this.editorTarget.addEventListener("trix-initialize", this.addVideoButton.bind(this))
  }

  addVideoButton(event) {
    const trixElement = event.target
    const toolbar = trixElement.toolbarElement
    const fileTools = toolbar.querySelector(".trix-button-group--file-tools")
    if (!fileTools || fileTools.querySelector("[data-trix-action='video']")) return

    fileTools.insertAdjacentHTML("beforeend", `
      <button type="button" class="trix-button" data-trix-action="video" title="Insérer une vidéo" tabindex="-1">🎬</button>
    `)

    fileTools.addEventListener("click", (e) => {
      if (e.target.closest("[data-trix-action='video']")) this.insertVideo(trixElement)
    })
  }

  insertVideo(trixElement) {
    const url = prompt("Collez l'URL YouTube ou Vimeo :")
    if (!url) return

    const embedHtml = this.buildEmbed(url.trim())
    if (!embedHtml) {
      alert("URL non reconnue (YouTube ou Vimeo uniquement).")
      return
    }

    const attachment = new Trix.Attachment({
      content: embedHtml,
      contentType: "application/vnd.actiontext.video-embed"
    })
    trixElement.editor.insertAttachment(attachment)
    trixElement.editor.insertLineBreak()
  }

  buildEmbed(url) {
    let match = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([\w-]{6,})/)
    if (match) {
      return `<div class="aspect-video my-4"><iframe src="https://www.youtube.com/embed/${match[1]}" class="w-full h-full" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen loading="lazy"></iframe></div>`
    }

    match = url.match(/vimeo\.com\/(\d+)/)
    if (match) {
      return `<div class="aspect-video my-4"><iframe src="https://player.vimeo.com/video/${match[1]}" class="w-full h-full" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen loading="lazy"></iframe></div>`
    }

    return null
  }
}