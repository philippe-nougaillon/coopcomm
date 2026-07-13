


























import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="conversation"
//
// Gère le fil de discussion de la messagerie : scroll automatique au chargement,
// badge "Nouveau message", et accusés de lecture (mark_as_read).
//
// Le scroll se fait sur containerTarget (et non sur window), car ce conteneur
// possède son propre overflow-y-auto (layout flex avec header/footer fixes).
export default class extends Controller {
  static targets = ["container", "badge", "input"]
  static values = { toId: Number }

  connect() {
    this.scrollToCorrectPosition()
    this.setupMessageObserver()
    this.setupReadReceipts()

    this.onScroll = this.handleScroll.bind(this)
    if (this.hasContainerTarget) {
      this.containerTarget.addEventListener("scroll", this.onScroll)
    }

    this.setupViewportHandler()
  }

  disconnect() {
    if (this.messageObserver) this.messageObserver.disconnect()
    if (this.readObserver) this.readObserver.disconnect()
    if (this.hasContainerTarget) {
      this.containerTarget.removeEventListener("scroll", this.onScroll)
    }
    this.teardownViewportHandler()
  }

  // Au chargement : on se positionne sur le premier message non lu, sinon tout en bas.
  scrollToCorrectPosition() {
    if (!this.hasContainerTarget) return

    const unreadBanner = this.element.querySelector("#first-unread-banner")
    if (unreadBanner) {
      const containerRect = this.containerTarget.getBoundingClientRect()
      const bannerRect = unreadBanner.getBoundingClientRect()
      const offset = bannerRect.top - containerRect.top + this.containerTarget.scrollTop - 20
      this.containerTarget.scrollTo({ top: offset, behavior: "instant" })
    } else {
      this.scrollToBottom("instant")
    }
  }

  scrollToBottom(behavior = "instant") {
    if (!this.hasContainerTarget) return
    this.containerTarget.scrollTo({ top: this.containerTarget.scrollHeight, behavior })
    this.hideBadge()
  }

  // Action : clic sur le badge "Nouveau message"
  jumpToBottom() {
    this.scrollToBottom("smooth")
  }

  // Action : envoi d'un message (soumission du formulaire / touche Entrée).
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
          const container = this.containerTarget
          const distanceToBottom =
            container.scrollHeight - (container.scrollTop + container.clientHeight)
          const isNearBottom = distanceToBottom - newNodeHeight <= 150

          if (isMyMessage) {
            this.scrollToBottom("smooth")
          } else if (isNearBottom) {
            const nodeOffset = node.offsetTop - 20
            container.scrollTo({ top: nodeOffset, behavior: "smooth" })
            this.hideBadge()
          } else {
            this.showBadge()
          }

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
      // root: le conteneur scrollable lui-même, pas le viewport global
      { root: this.hasContainerTarget ? this.containerTarget : null, threshold: 0, rootMargin: "0px 0px -50px 0px" }
    )

    this.element
      .querySelectorAll('.message-wrapper[data-unread="true"]')
      .forEach((msg) => this.readObserver.observe(msg))
  }

  // Cache le badge quand on est déjà tout en bas du fil.
  handleScroll() {
    if (!this.hasContainerTarget) return
    const container = this.containerTarget
    const distanceToBottom = container.scrollHeight - (container.scrollTop + container.clientHeight)
    if (distanceToBottom <= 50) this.hideBadge()
  }

  showBadge() {
    if (this.hasBadgeTarget) this.badgeTarget.classList.remove("hidden")
  }

  hideBadge() {
    if (this.hasBadgeTarget) this.badgeTarget.classList.add("hidden")
  }

  // --- Gestion du clavier virtuel (mobile) ---
  //
  // Sans "interactive-widget=resizes-content" dans le meta viewport, "h-dvh" ne se
  // recalcule pas toujours quand le clavier apparaît. On corrige ça manuellement via
  // l'API visualViewport, en ajustant la hauteur du conteneur racine et en gardant
  // le bas du fil visible.
  setupViewportHandler() {
    if (!window.visualViewport) return // navigateur trop ancien : on ignore silencieusement

    this.rootElement = this.element.closest(".drawer-content")
    if (!this.rootElement) return

    this.baseHeight = null
    this.viewportHandler = () => this.handleViewportResize()
    window.visualViewport.addEventListener("resize", this.viewportHandler)
  }

  teardownViewportHandler() {
    if (window.visualViewport && this.viewportHandler) {
      window.visualViewport.removeEventListener("resize", this.viewportHandler)
    }
    if (this.rootElement) {
      this.rootElement.style.height = ""
    }
  }

  handleViewportResize() {
    if (!this.rootElement) return

    const vv = window.visualViewport
    // Mémorise la hauteur "clavier fermé" au premier événement, pour comparer ensuite.
    if (this.baseHeight === null) this.baseHeight = vv.height

    const keyboardOpen = this.baseHeight - vv.height > 100 // seuil pour ignorer les micro-variations

    if (keyboardOpen) {
      this.rootElement.style.height = `${vv.height}px`
      this.scrollToBottom("instant")
    } else {
      this.rootElement.style.height = ""
    }
  }
}