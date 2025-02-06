import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="calc-temps-passe"
export default class extends Controller {
  static targets = ['debut', 'fin', 'pause', 'agents', 'temps']
  connect() {
    // console.log('Hello, Stimulus! TEMPS PASSE', this.element)
  }

  initialize() {
    this.calc()
  }

  calc() {
    let temps = this.tempsTarget
    if (this.debutTarget.value != "" && this.finTarget.value != "") {
      let debut = new Date(this.debutTarget.value)
      let fin = new Date(this.finTarget.value)
      let temps_pause = this.pauseTarget.value

      if (fin > debut) {
        let temps_passé = Math.abs(fin - debut) / (1000 * 60 * 60)
        let temps_total = temps_passé - temps_pause

        // Si plusieurs agents sont sélectionnés, multiplier par le nombre d'agents
        if (this.agentsTarget.selectedOptions.length > 0) {
          temps_total = temps_total * this.agentsTarget.selectedOptions.length
        }

        temps.value = temps_total.toFixed(2)
        temps.classList.remove('!text-red-500')
        temps.classList.add('!text-green-500')
      } else {
        temps.value = -1
        temps.classList.add('!text-red-500')
        temps.classList.remove('!text-green-500')
      }
    } else {
      temps.value = 0
      temps.classList.remove('!text-green-500')
      temps.classList.remove('!text-red-500')
    }
  }
}
