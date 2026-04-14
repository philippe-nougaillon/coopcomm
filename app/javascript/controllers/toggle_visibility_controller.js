import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "hideable", "field"]

  connect() {
    // Au chargement, on mémorise si le champ était déjà désactivé par le serveur
    // (très utile pour ton champ météo conditionnel)
    this.fieldTargets.forEach(field => {
      field.dataset.initialDisabled = field.disabled
    })

    this.toggle()
  }

  toggle() {
    const isChecked = this.checkboxTarget.checked

    if (isChecked) {
      // On cache la zone
      this.hideableTarget.classList.add("hidden")

      // On désactive tous les champs ciblés pour qu'ils ne soient pas envoyés
      this.fieldTargets.forEach(field => {
        field.disabled = true
      })
    } else {
      // On affiche la zone
      this.hideableTarget.classList.remove("hidden")

      // On réactive les champs, mais SEULEMENT s'ils n'étaient pas désactivés à l'origine
      this.fieldTargets.forEach(field => {
        field.disabled = field.dataset.initialDisabled === "true"
      })
    }
  }
}