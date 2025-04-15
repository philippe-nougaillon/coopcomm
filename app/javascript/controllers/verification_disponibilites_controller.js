import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="verification-disponibilites"
export default class extends Controller {

  static targets = [ "agent" ]

  date_debut_prevue = null
  date_debut_prevue_hour = null
  date_debut_prevue_minute = null

  date_fin_prevue = null
  date_fin_prevue_hour = null
  date_fin_prevue_minute = null

  verif(event){
    let value_date = event.target.value

    this.setValues(event, value_date);

    let date_début_prévue_to_send = this.createDate(this.date_debut_prevue, this.date_debut_prevue_hour, this.date_debut_prevue_minute)
    let date_fin_prévue_to_send = this.createDate(this.date_fin_prevue, this.date_fin_prevue_hour, this.date_fin_prevue_minute)

    if(date_début_prévue_to_send || date_fin_prévue_to_send){
      this.get_unavailable_elements(date_début_prévue_to_send, date_fin_prévue_to_send);
    }



    //TODO: Récupérer tous les agents avec la target

  }

  get_unavailable_elements(date_début_prévue_to_send, date_fin_prévue_to_send) {
    console.log("Lancement de la requête")
    const url = this.getUrl(date_début_prévue_to_send, date_fin_prévue_to_send);

    this.request_unavailable_elements(url)
        .then(response => console.log(response))
        .catch(error => {
              console.error("Erreur réseau :", error);
              alert("Une erreur réseau est survenue. Veuillez réessayer.");
            }
        )
  }

  createDate(date, hour, minute){
    if(date && hour && minute){
      return new Date(date + " " + hour + ":" + minute)
    }else{
      return null
    }
  }

  getUrl(date_début_prévue_to_send, date_fin_prévue_to_send) {
    const begin_url = window.location.protocol + "//" + window.location.host

    const end_url = "/interventions/get_unavailable_elements?date_debut_prevue=" + date_début_prévue_to_send + "&date_fin_prevue=" + date_fin_prévue_to_send

    return begin_url + end_url;
  }

  setValues(event, value_date) {
    switch (event.target.id) {
      case "intervention_début_prévue":
        this.date_debut_prevue = value_date
        break
      case "intervention_début_prévue_hour":
        this.date_debut_prevue_hour = value_date
        break
      case "intervention_début_prévue_minute":
        this.date_debut_prevue_minute = value_date
        break
      case "intervention_fin_prévue":
        this.date_fin_prevue = value_date
        break
      case "intervention_fin_prévue_hour":
        this.date_fin_prevue_hour = value_date
        break
      case "intervention_fin_prévue_minute":
        this.date_fin_prevue_minute = value_date
        break
    }
  }

  async request_unavailable_elements(url){
    try {
      const response = await fetch(url, {
        method: "Get",
        headers: { "X-Requested-With": "XMLHttpRequest" },
      });

      if (response.ok) {
        return await response.json()
      }else{
        const errorResult = await response.json();
        console.error("Erreur :", errorResult.errors.join(", "));
        alert(`Erreur : ${errorResult.errors.join(", ")}`);
      }
    } catch (error) {
      console.error("Erreur réseau :", error);
      alert("Une erreur réseau est survenue. Veuillez réessayer.");
    }
  }
}
