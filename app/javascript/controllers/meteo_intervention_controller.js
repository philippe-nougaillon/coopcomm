import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs";

// Connects to data-controller="meteo-intervention"
export default class extends Controller {

  // Si début prévue a quelque chose, demander la météo pour ce datetime
  static targets = ["debut_prevue", "debut_prevue_hour", "prévisionMétéo"]

  afficher_meteo() {

    let meteo_text = "météo"

    this.fetch_meteo_by_day()
  }

  fetch_meteo_by_day() {
    Rails.ajax({
      type: "GET",
      url: "/meteo_by_day.json",
      success: (response) => {
        console.log(response)
        this.prévisionMétéoTarget.textContent = response.forecast
      },
      error: (err) => {
        this.prévisionMétéoTarget.textContent = err
      }
    })
  }
}
