import { Controller } from "@hotwired/stimulus"

// Menu mobile : ouvre, ferme, et change l'icône
export default class extends Controller {
  static targets = ["menu", "button", "menuIcon", "closeIcon"]

  toggle() {
    this.setOpen(this.menuTarget.classList.contains("hidden"))
  }

  close() {
    this.setOpen(false)
  }

  setOpen(open) {
    this.menuTarget.classList.toggle("hidden", !open)
    this.menuIconTarget.classList.toggle("hidden", open)
    this.closeIconTarget.classList.toggle("hidden", !open)
    this.buttonTarget.setAttribute("aria-expanded", String(open))
  }
}