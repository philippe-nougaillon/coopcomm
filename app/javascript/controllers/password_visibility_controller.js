import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="password-visibility"
export default class extends Controller {
  connect() {
    console.log("Hello")
  }

  static targets = ["input", "showIcon", "hideIcon"]

  toggle(event) {
    // Empêche le clic sur l'icône de soumettre le formulaire par accident
    event.preventDefault()

    if (this.inputTarget.type === "password") {
      this.inputTarget.type = "text"
      this.showIconTarget.classList.add("hidden")
      this.hideIconTarget.classList.remove("hidden")
    } else {
      this.inputTarget.type = "password"
      this.showIconTarget.classList.remove("hidden")
      this.hideIconTarget.classList.add("hidden")
    }
  }
}
