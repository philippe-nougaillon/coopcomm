import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="cotation-ligne"
// Préremplit le prix HT et l'intitulé depuis la prestation choisie,
// puis affiche le sous-total (prix × quantité) de la ligne.
export default class extends Controller {
  static targets = ["prestation", "prix", "intitule", "qte", "total"]

  connect() {
    this.refresh()
  }

  prestationChanged() {
    const option = this.prestationTarget.selectedOptions[0]
    if (!option || !option.value) return

    const tarif = option.dataset.tarif
    if (tarif && this.hasPrixTarget && !this.prixTarget.value) {
      this.prixTarget.value = tarif
    }
    if (this.hasIntituleTarget && !this.intituleTarget.value) {
      this.intituleTarget.value = option.dataset.libelle || ""
    }
    this.refresh()
  }

  refresh() {
    if (!this.hasTotalTarget) return
    const prix = parseFloat(this.hasPrixTarget ? this.prixTarget.value : 0) || 0
    const qte = parseFloat(this.hasQteTarget ? this.qteTarget.value : 0) || 0
    this.totalTarget.textContent = (prix * qte).toLocaleString("fr-FR", {
      style: "currency",
      currency: "EUR",
    })
  }
}
