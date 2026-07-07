import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="cotation-ligne"
// Le prix unitaire n'est pas saisissable : il provient de la prestation choisie.
// À chaque changement de prestation (ou de quantité), on met à jour l'affichage
// du prix unitaire ET du sous-total (prix × quantité), formatés en euros.
export default class extends Controller {
  static targets = ["prestation", "prix", "intitule", "qte", "total"]

  connect() {
    this.refresh()
  }

  prestationChanged() {
    const option = this.prestationTarget.selectedOptions[0]
    // Pré-remplit l'intitulé (optionnel) depuis la prestation si encore vide
    if (option && option.value && this.hasIntituleTarget && !this.intituleTarget.value) {
      this.intituleTarget.value = option.dataset.libelle || ""
    }
    this.refresh()
  }

  refresh() {
    const option = this.prestationTarget.selectedOptions[0]
    const hasPrestation = !!(option && option.value)
    const tarif = hasPrestation ? parseFloat(option.dataset.tarif) || 0 : 0
    const qte = parseFloat(this.hasQteTarget ? this.qteTarget.value : 0) || 0

    const fmt = (n) => n.toLocaleString("fr-FR", { style: "currency", currency: "EUR" })

    if (this.hasPrixTarget) this.prixTarget.textContent = hasPrestation ? fmt(tarif) : "—"
    if (this.hasTotalTarget) this.totalTarget.textContent = hasPrestation ? fmt(tarif * qte) : "—"
  }
}
