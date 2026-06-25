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
  document.removeEventListener("click", this.closeOnOutsideClick)
  if (this._closeHandler) {
    document.removeEventListener("click", this._closeHandler)
  }
}

  closeOnOutsideClick(e) {
    if (!this.element.contains(e.target)) {
      this.element.removeAttribute("open");
    }
  }

  // pour le popup  + X en general//
  static targets = ["menu"]

  togglePortal(event) {
  // Garde la référence même après téléportation
  if (!this._menu && this.hasMenuTarget) {
    this._menu = this.menuTarget
  }
  if (!this._menu) return

  const menu = this._menu
  const btn = event.currentTarget

  if (menu.classList.contains("hidden")) {
    document.body.appendChild(menu)
    const rect = btn.getBoundingClientRect()
    const menuWidth = 208

    menu.style.position = "fixed"
    menu.style.zIndex = "9999"

    if (rect.left + menuWidth > window.innerWidth) {
      menu.style.left = `${window.innerWidth - menuWidth - 8}px`
    } else {
      menu.style.left = `${rect.left}px`
    }

    menu.classList.remove("hidden")
    menu.classList.add("flex")

    requestAnimationFrame(() => {
      menu.style.top = `${rect.top - menu.offsetHeight - 8}px`

      this._closeHandler = (e) => {
        if (!menu.contains(e.target) && e.target !== btn) {
          menu.classList.add("hidden")
          menu.classList.remove("flex")
          document.removeEventListener("click", this._closeHandler)
        }
      }
      document.addEventListener("click", this._closeHandler)
    })

  } else {
    menu.classList.add("hidden")
    menu.classList.remove("flex")
    document.removeEventListener("click", this._closeHandler)
  }
}
}