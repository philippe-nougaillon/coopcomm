import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="conversation"
//
// Gère le fil de discussion de la messagerie : scroll automatique au chargement,
// badge "Nouveau message", et accusés de lecture (mark_as_read).
//
// Implémenté en contrôleur Stimulus (et non en <script> inline) car Turbo ré-évalue
// les <script> du <body> à chaque rendu/restauration de page : un script inline
// redéclarait ses variables (SyntaxError au retour navigateur) et empilait des
// écouteurs/observers. Stimulus gère proprement le cycle de vie via connect/disconnect.
export default class extends Controller {
  static targets = ["container", "badge", "input"]
  static values = { toId: Number }

  connect() {
    this.scrollToCorrectPosition()
    this.setupMessageObserver()
    this.setupReadReceipts()

    this.onScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.onScroll)
  }

  disconnect() {
    if (this.messageObserver) this.messageObserver.disconnect()
    if (this.readObserver) this.readObserver.disconnect()
    window.removeEventListener("scroll", this.onScroll)
  }

  // Au chargement : on se positionne sur le premier message non lu, sinon tout en bas.
  scrollToCorrectPosition() {
    const unreadBanner = this.element.querySelector("#first-unread-banner")
    if (unreadBanner) {
      const y = unreadBanner.getBoundingClientRect().top + window.scrollY - 100
      window.scrollTo({ top: y, behavior: "instant" })
    } else {
      this.scrollToBottom("instant")
    }
  }

  scrollToBottom(behavior = "instant") {
    window.scrollTo({ top: document.documentElement.scrollHeight, behavior })
    this.hideBadge()
  }

  // Action : clic sur le badge "Nouveau message"
  jumpToBottom() {
    this.scrollToBottom("smooth")
  }

  // Action : envoi d'un message (soumission du formulaire / touche Entrée).
  // Le message envoyé est affiché via le broadcast Turbo Stream du modèle Message ;
  // on se contente ici de poster puis de vider le champ.
  send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (message === "") return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch("/messagerie/send_message", {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({ message, to_id: this.toIdValue }),
    }).then((response) => {
      if (response.ok) {
        this.inputTarget.value = ""
        this.inputTarget.focus()
      }
    })
  }

  // Surveille l'arrivée de nouveaux messages (insérés par Turbo Stream) dans le fil.
  setupMessageObserver() {
    if (!this.hasContainerTarget) return

    this.messageObserver = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType !== Node.ELEMENT_NODE) return

          const isMyMessage =
            node.classList.contains("chat-end") || node.querySelector(".chat-end") !== null
          const newNodeHeight = node.offsetHeight || 0
          const scrollPosition = window.innerHeight + window.scrollY
          const distanceToBottom = document.documentElement.scrollHeight - scrollPosition
          const isNearBottom = distanceToBottom - newNodeHeight <= 150

          if (isMyMessage) {
            this.scrollToBottom("smooth")
          } else if (isNearBottom) {
            const offsetPosition = node.getBoundingClientRect().top + window.scrollY - 120
            window.scrollTo({ top: offsetPosition, behavior: "smooth" })
            this.hideBadge()
          } else {
            this.showBadge()
          }

          // Message reçu en direct et non lu : on le surveille pour l'accusé de lecture.
          if (!isMyMessage && this.readObserver && node.dataset?.unread === "true") {
            this.readObserver.observe(node)
          }
        })
      })
    })

    this.messageObserver.observe(this.containerTarget, { childList: true })
  }

  // Marque les messages comme lus dès qu'ils deviennent visibles à l'écran.
  setupReadReceipts() {
    this.readObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return

          const messageNode = entry.target
          const messageId = messageNode.dataset.messageId
          const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

          fetch("/messagerie/mark_as_read", {
            method: "POST",
            headers: {
              "X-CSRF-Token": csrfToken,
              "Content-Type": "application/json",
              Accept: "application/json",
            },
            body: JSON.stringify({ id: messageId }),
          })

          this.readObserver.unobserve(messageNode)
          messageNode.dataset.unread = "false"
        })
      },
      // Déclenche dès qu'une partie du message entre d'au moins 50px dans l'écran.
      { threshold: 0, rootMargin: "0px 0px -50px 0px" }
    )

    this.element
      .querySelectorAll('.message-wrapper[data-unread="true"]')
      .forEach((msg) => this.readObserver.observe(msg))
  }

  // Cache le badge quand on est déjà tout en bas du fil.
  handleScroll() {
    const scrollPosition = window.innerHeight + window.scrollY
    const distanceToBottom = document.documentElement.scrollHeight - scrollPosition
    if (distanceToBottom <= 50) this.hideBadge()
  }

  showBadge() {
    if (this.hasBadgeTarget) this.badgeTarget.classList.remove("hidden")
  }

  hideBadge() {
    if (this.hasBadgeTarget) this.badgeTarget.classList.add("hidden")
  }
}
