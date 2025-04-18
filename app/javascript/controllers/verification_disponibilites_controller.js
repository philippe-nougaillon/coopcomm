import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="verification-disponibilites"
export default class extends Controller {

  // Cible le slim select des agents
  static targets = ["agents", "formAgents", "debut_prevue", "debut_prevue_hour", "debut_prevue_minute", "fin_prevue", "fin_prevue_hour", "fin_prevue_minute"]

  // Variables d'instance pour début_prévue
  date_debut_prevue = null
  date_debut_prevue_hour = null
  date_debut_prevue_minute = null

  // Variables d'instance pour fin_prévue
  date_fin_prevue = null
  date_fin_prevue_hour = null
  date_fin_prevue_minute = null

  // Variable d'instance pour la liste des agent ids en conflit
  conflicting_agents_ids = null

  initialize() {
    this.updateDates()
  }

  connect() {
    // Initialise un observeur sur les agents pour mettre en rouge le tags si l'agent est en conflit. Seul moyen tant qu'il y a slim select.
    this.observeSlimSelectTags()

    this.change()
  }

  observeSlimSelectTags() {
    const agentsContainer = this.formAgentsTarget.querySelector(".ss-values")

    const observer = new MutationObserver(mutations => {
      for (const mutation of mutations) {
        if (mutation.addedNodes.length > 0) {
          this.updateAgentTags()
        }
      }
    })

    observer.observe(agentsContainer, { childList: true, subtree: true })
  }

  // Fonction appelée à chaque changement d'une valeur des dates prévues
  verif(event) {

    this.updateDatesByEvent(event, event.target.value);

    this.change()

  }

  change() {
    let date_début_prévue_to_send = this.createDate(this.date_debut_prevue, this.date_debut_prevue_hour, this.date_debut_prevue_minute)
    let date_fin_prévue_to_send = this.createDate(this.date_fin_prevue, this.date_fin_prevue_hour, this.date_fin_prevue_minute)

    const agentsSelectedOptions = this.agentsTarget.slim.select.getSelectedOptions()

    const agentsOptions = this.agentsTarget.options

    let agent_ids = []

    for (let i = 1; i < agentsOptions.length; i++) {
      agent_ids.push(agentsOptions[i].value)
    }

    if (agent_ids && (date_début_prévue_to_send || date_fin_prévue_to_send)) {

      this.get_unavailable_elements(agent_ids, date_début_prévue_to_send, date_fin_prévue_to_send).then(
        conflicting_agents_ids => {
          this.conflicting_agents_ids = conflicting_agents_ids
          if (this.conflicting_agents_ids) {
            for (let i = 0; i < agentsOptions.length; i++) {
              let option_agent = agentsOptions[i]
              let option_agent_id = parseInt(option_agent.value)
              if (this.conflicting_agents_ids.includes(option_agent_id)) {
                option_agent.style = "background-color:red;"
              } else {
                option_agent.style = ""
              }
            }

            this.updateAgentTags()
          }
        }
      );
    }

  }

  updateAgentTags() {
    this.formAgentsTarget.querySelectorAll(".ss-values .ss-value").forEach(tag => {
      console.log(tag)
      const agentName = tag.querySelector('.ss-value-text')
      console.log(this.conflicting_agents_ids)
      // Récupérer le nom de l'agent selectionné dans le select

      if (this.conflicting_agents_ids) {
        tag.style = "background-color:red;"
      } else {
        tag.style = ""
      }

    })

    //TODO: Mettre en rouge en fonction de l'agent id du conflit
    //TODO: Enlever le rouge quand plus de conflit
  }

  get_unavailable_elements(agent_ids, date_début_prévue_to_send, date_fin_prévue_to_send) {
    //console.log("Lancement de la requête")
    const url = this.getUrl(agent_ids, date_début_prévue_to_send, date_fin_prévue_to_send);

    //console.log("URL générée :", url);

    //TODO: Voir si garder le try-catch dans la fonction ou mettre le then directement
    return this.request_unavailable_elements(url)
  }

  createDate(date, hour, minute) {
    if (date && hour && minute) {
      return new Date(`${date}T${hour.padStart(2, '0')}:${minute.padStart(2, '0')}:00`).toISOString(); // ChatGPT
    } else {
      return null
    }
  }

  getUrl(agent_ids, date_début_prévue_to_send, date_fin_prévue_to_send) {
    const begin_url = window.location.protocol + "//" + window.location.host

    const end_url = "/interventions/get_unavailable_elements?agents=" + agent_ids + "&date_debut_prevue=" + date_début_prévue_to_send + "&date_fin_prevue=" + date_fin_prévue_to_send

    return begin_url + end_url;
  }

  updateDates() {
    if (this.debut_prevueTarget.value) {
      this.date_debut_prevue = this.debut_prevueTarget.value
    }
    if (this.debut_prevue_hourTarget.value) {
      this.date_debut_prevue_hour = this.debut_prevue_hourTarget.value
    }
    if (this.debut_prevue_minuteTarget.value) {
      this.date_debut_prevue_minute = this.debut_prevue_minuteTarget.value
    }
    if (this.fin_prevueTarget.value) {
      this.date_fin_prevue = this.fin_prevueTarget.value
    }
    if (this.fin_prevue_hourTarget.value) {
      this.date_fin_prevue_hour = this.fin_prevue_hourTarget.value
    }
    if (this.fin_prevue_minuteTarget.value) {
      this.date_fin_prevue_minute = this.fin_prevue_minuteTarget.value
    }
  }

  updateDatesByEvent(event, value_date) {
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

  async request_unavailable_elements(url) {
    try {
      const response = await fetch(url, {
        method: "Get",
        headers: { "X-Requested-With": "XMLHttpRequest" },
      });

      if (response.ok) {
        return await response.json()
      } else {
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
