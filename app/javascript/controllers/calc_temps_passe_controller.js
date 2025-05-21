import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="calc-temps-passe"
export default class extends Controller {
  static targets = ['debut_date', 'debut_hour', 'debut_minute', 'fin_date', 'fin_hour', 'fin_minute', 'pause', 'agents', 'temps']
  connect() {
    // console.log('Hello, Stimulus! TEMPS PASSE', this.element)
  }

  initialize() {
    this.calc()
  }

  calc() {
    let temps = this.tempsTarget
    if (this.debut_dateTarget.value != "" && this.fin_dateTarget.value != "") {
      console.log("permier test passé")
      console.log(this.debut_dateTarget.value)
      console.log(this.debut_hourTarget.value)
      console.log(this.debut_minuteTarget.value)
      let debut = this.buildDate(
        this.debut_dateTarget.value,
        this.debut_hourTarget.value,
        this.debut_minuteTarget.value
      )
      let fin = this.buildDate(
        this.fin_dateTarget.value,
        this.fin_hourTarget.value,
        this.fin_minuteTarget.value
      )
      let temps_pause = this.pauseTarget.value
      console.log("Debut : " + debut)

      if (fin > debut) {
        const temps_passé = (fin - debut) / (1000 * 60 * 60)
        let temps_total = temps_passé - temps_pause

        if (this.agentsTarget.selectedOptions.length > 0) {
          temps_total *= this.agentsTarget.selectedOptions.length
        }

        temps.value = temps_total.toFixed(2)
        temps.classList.remove('text-red-500!')
        temps.classList.add('text-green-500!')
      } else {
        temps.value = -1
        temps.classList.add('text-red-500!')
        temps.classList.remove('text-green-500!')
      }
    } else {
      temps.value = 0
      temps.classList.remove('text-green-500!', 'text-red-500!')
    }
  }

  buildDate(dateStr, hourStr, minuteStr) {
    // Passer d'une String à un Nombre pour la création 
    const [year, month, day] = dateStr.split('-').map(Number)

    // // Passer d'une String à un Nombre pour la création (nombre en base 10, ou 0)
    const hour = parseInt(hourStr, 10) || 0
    const minute = parseInt(minuteStr, 10) || 0

    // Retourne -1 parce que dans JS, les mois commence à 0
    return new Date(year, month - 1, day, hour, minute)
  }
}
