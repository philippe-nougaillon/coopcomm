import { Controller } from "@hotwired/stimulus"

// Gère les onglets accessibles (clic, clavier, hash d'URL optionnel)
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = {
    index: { type: Number, default: 0 },
    hashPrefix: String
  }

  connect() {
    if (this.hasHashPrefixValue) {
      this.onHashChange = this.selectFromHash.bind(this)
      window.addEventListener("hashchange", this.onHashChange)
      this.selectFromHash()
    }
  }

  disconnect() {
    if (this.onHashChange) window.removeEventListener("hashchange", this.onHashChange)
  }

  select(event) {
    this.indexValue = this.tabTargets.indexOf(event.currentTarget)
  }

  keydown(event) {
    const last = this.tabTargets.length - 1
    const current = this.indexValue

    const moves = {
      ArrowDown:  current === last ? 0 : current + 1,
      ArrowRight: current === last ? 0 : current + 1,
      ArrowUp:    current === 0 ? last : current - 1,
      ArrowLeft:  current === 0 ? last : current - 1,
      Home: 0,
      End: last
    }

    const next = moves[event.key]
    if (next === undefined) return

    event.preventDefault()
    this.indexValue = next
    this.tabTargets[next].focus()
  }

  // Stimulus appelle cette méthode au chargement et à chaque changement de indexValue
  indexValueChanged() {
    this.tabTargets.forEach((tab, i) => {
      const active = i === this.indexValue
      tab.dataset.active = active
      tab.setAttribute("aria-selected", active)
      tab.tabIndex = active ? 0 : -1
    })

    this.panelTargets.forEach((panel, i) => {
      panel.dataset.active = i === this.indexValue
    })
  }

  selectFromHash() {
    const prefix = `#${this.hashPrefixValue}`
    if (!location.hash.startsWith(prefix)) return

    const id = location.hash.replace(prefix, "")
    const index = this.tabTargets.findIndex(tab => tab.dataset.id === id)
    if (index < 0) return

    this.indexValue = index
    this.element.scrollIntoView()
  }
}