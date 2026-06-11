// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this);
    document.addEventListener("click", this.closeOnOutsideClick);
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        document
          .querySelectorAll("details[open]")
          .forEach((d) => d.removeAttribute("open"));
      }
    });
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick);
  }

  closeOnOutsideClick(e) {
    if (!this.element.contains(e.target)) {
      this.element.removeAttribute("open");
    }
  }
}
