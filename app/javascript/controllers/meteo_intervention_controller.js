import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs";

// Connects to data-controller="meteo-intervention"
export default class extends Controller {

  static targets = ["debut_prevue", "debut_prevue_hour", "prévisionMétéo"]

  connect() {
    if (this.debut_prevueTarget.value) {
      this.afficher_meteo()
    }
  }

  afficher_meteo() {
    this.get_meteo_by_daily()
  }

  get_meteo_by_daily() {

    let days = this.debut_prevueTarget.value

    let diffDays = this.nombres_jours(days)

    if (diffDays < 0 || diffDays > 13 || isNaN(diffDays)) {
      this.prévisionMétéoTarget.value = "Prévision uniquement dans les 14 prochains jours"
    } else {
      this.fetch_meteo_by_daily(diffDays)
    }
  }

  fetch_meteo_by_daily(diffDays) {
    Rails.ajax({
      type: "GET",
      url: "/meteo_by_day.json",
      data: "day=" + diffDays,
      success: (response) => {
        const forecast = response["forecast"]
        console.log(forecast)
        this.prévisionMétéoTarget.value = response["weather"] + " | Température : " + forecast["temp2m"] + "°C | Probabilité de pluie : " + forecast["probarain"] + "% | Vent : " + forecast["wind10m"] + " km/h"
      },
      error: (err) => {
        this.prévisionMétéoTarget.value = "Météo indisponible."
      }
    })
  }

  nombres_jours(inputValue) {
    // Convertit la valeur en objet Date
    const selectedDate = new Date(inputValue);

    // Récupère la date actuelle (sans l’heure)
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Calcule la différence en millisecondes, puis en jours
    const diffTime = selectedDate - today;
    return Math.round(diffTime / (1000 * 60 * 60 * 24));
  }
}
