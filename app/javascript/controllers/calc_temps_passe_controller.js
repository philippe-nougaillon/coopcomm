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

      if (fin > debut) {
        const temps_passe_brut = (fin - debut) / (1000 * 60 * 60)
        let temps_par_agent = temps_passe_brut - temps_pause // Le temps unitaire
        let temps_total = temps_par_agent

        if (this.agentsTarget.selectedOptions.length > 0) {
          temps_total *= this.agentsTarget.selectedOptions.length
        }

        // Mise à jour du temps total
        temps.value = temps_total.toFixed(2)
        if (temps.value > 0) {
          temps.classList.remove('text-red-500!')
          temps.classList.add('text-green-500!')
        }
        else {
          temps.classList.add('text-red-500!')
          temps.classList.remove('text-green-500!')
        }

        // Mise à jour du temps par agent
        if (this.hasTempsParAgentTarget) {
          this.tempsParAgentTarget.value = temps_par_agent.toFixed(2)
          if (temps_par_agent > 0) {
            this.tempsParAgentTarget.classList.remove('text-red-500!')
            this.tempsParAgentTarget.classList.add('text-green-500!')
          } else {
            this.tempsParAgentTarget.classList.add('text-red-500!')
            this.tempsParAgentTarget.classList.remove('text-green-500!')
          }
        }

      } else {
        // En cas d'erreur de dates (fin < début)
        temps.value = -1
        temps.classList.add('text-red-500!')
        temps.classList.remove('text-green-500!')

        if (this.hasTempsParAgentTarget) {
          this.tempsParAgentTarget.value = -1
          this.tempsParAgentTarget.classList.add('text-red-500!')
          this.tempsParAgentTarget.classList.remove('text-green-500!')
        }
      }
    } else {
      // Si les dates ne sont pas remplies
      temps.value = 0
      temps.classList.remove('text-green-500!', 'text-red-500!')

      if (this.hasTempsParAgentTarget) {
        this.tempsParAgentTarget.value = 0
        this.tempsParAgentTarget.classList.remove('text-green-500!', 'text-red-500!')
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