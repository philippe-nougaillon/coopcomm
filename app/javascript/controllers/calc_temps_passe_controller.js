import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="calc-temps-passe"
export default class extends Controller {
  static targets = ['debut_date', 'debut_hour', 'debut_minute', 'fin_date', 'fin_hour', 'fin_minute', 'pause', 'agents', 'temps', 'tempsParAgent']

  connect() {
    // console.log('Hello, Stimulus! TEMPS PASSE', this.element)
  }

  initialize() {
    this.calc()
  }

  applyColor(element, val) {
    const numericVal = parseFloat(val)
    element.classList.toggle('text-green-500!', numericVal > 0)
    element.classList.toggle('text-red-500!', numericVal < 0)
    element.classList.toggle('text-slate-500!', numericVal === 0)
  }

  calc() {
    let temps = this.tempsTarget
    
    if (this.debut_dateTarget.value != "" && this.fin_dateTarget.value != "" &&
    this.debut_hourTarget.value != "" && this.debut_minuteTarget.value != "" &&
    this.fin_hourTarget.value != "" && this.fin_minuteTarget.value != "") {
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

      if (fin >= debut) {
        const temps_passe_brut = (fin - debut) / (1000 * 60 * 60)
        let temps_par_agent = temps_passe_brut - temps_pause // Le temps unitaire
        let temps_total = temps_par_agent

        if (this.agentsTarget.selectedOptions.length > 0) {
          temps_total *= this.agentsTarget.selectedOptions.length
        }

        // Mise à jour du temps total
        temps.value = temps_total.toFixed(2)
          this.applyColor(temps, temps_total)
        
        // Mise à jour du temps par agent
        if (this.hasTempsParAgentTarget) {
            this.tempsParAgentTarget.value = temps_par_agent.toFixed(2)
            this.applyColor(this.tempsParAgentTarget, temps_par_agent)
        }

      } else {
        // En cas d'erreur de dates (fin < début)
        temps.value = -1
        this.applyColor(temps, -1)

        if (this.hasTempsParAgentTarget) {
          this.tempsParAgentTarget.value = -1
          this.applyColor(this.tempsParAgentTarget, -1)
        }
      }
    } else {
      // Si les dates ne sont pas remplies
      temps.value = 0
      this.applyColor(temps, 0)

      if (this.hasTempsParAgentTarget) {
        this.tempsParAgentTarget.value = 0
        this.applyColor(this.tempsParAgentTarget, 0)
      }
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