import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  open() {
    try {
      if (typeof this.inputTarget.showPicker === "function") {
        this.inputTarget.showPicker()
      } else {
        this.inputTarget.focus()
      }
    } catch {
      this.inputTarget.focus()
    }
  }
}