import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { cookie: String }

  memoriser() {
    document.cookie = `${this.cookieValue}=${this.element.open ? "ouvert" : "ferme"}; path=/; max-age=31536000; samesite=lax`
  }
}
