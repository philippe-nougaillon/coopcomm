import { Controller } from "@hotwired/stimulus"

// Se conecta a cada <tr class="absence-row" data-controller="absence-status">.
// connect() se dispara SOLO cuando el elemento entra al DOM (incluye
// navegación Turbo), así que siempre recalcula contra la fecha real
// del navegador — nunca queda "atascado" por el fragment cache de Rails.
export default class extends Controller {
  static values = {
    du: String,
    au: String,
    matin: Boolean,
    apresMidi: Boolean
  }

  static targets = ["dot", "badge", "observation", "editBtn", "warning"]

  connect() {
    this.apply(this.isEnCours())
  }

  // Ajusta esta regla si Absence#en_cours? en el modelo Ruby es distinta
  // (p.ej. corte a mediodía para matin/après-midi).
  isEnCours() {
    if (!this.duValue || !this.auValue) return false
    const today = this.todayISO()
    return today >= this.duValue && today <= this.auValue
  }

  todayISO() {
    const d = new Date()
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, "0")
    const day = String(d.getDate()).padStart(2, "0")
    return `${y}-${m}-${day}`
  }

  apply(enCours) {
    this.element.classList.toggle("bg-amber-50/60", enCours)
    this.element.classList.toggle("hover:bg-amber-50", enCours)
    this.element.classList.toggle("text-amber-900", enCours)
    this.element.classList.toggle("hover:bg-base-200/60", !enCours)

    if (this.hasDotTarget) {
      this.dotTarget.innerHTML = enCours
        ? `<span class="relative flex h-2 w-2 shrink-0 mx-auto">
             <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-500 opacity-75"></span>
             <span class="relative inline-flex rounded-full h-2 w-2 bg-amber-500"></span>
           </span>`
        : ""
    }

    if (this.hasBadgeTarget) {
      this.badgeTarget.classList.toggle("bg-amber-100", enCours)
      this.badgeTarget.classList.toggle("text-amber-800", enCours)
      this.badgeTarget.classList.toggle("border-amber-200", enCours)
      this.badgeTarget.classList.toggle("bg-slate-100", !enCours)
      this.badgeTarget.classList.toggle("text-slate-600", !enCours)
      this.badgeTarget.classList.toggle("border-slate-300", !enCours)
    }

    if (this.hasObservationTarget) {
      this.observationTarget.classList.toggle("text-amber-800/80", enCours)
    }

    if (this.hasEditBtnTarget) {
      this.editBtnTarget.classList.toggle("bg-amber-600", enCours)
      this.editBtnTarget.classList.toggle("hover:bg-amber-700", enCours)
      this.editBtnTarget.classList.toggle("text-white", enCours)
      this.editBtnTarget.classList.toggle("border-none", enCours)
      this.editBtnTarget.classList.toggle("shadow-sm", enCours)
      this.editBtnTarget.classList.toggle("btn-primary", !enCours)
    }

    if (this.hasWarningTarget) {
      this.warningTarget.classList.toggle("hidden", !enCours)
    }
  }
}