import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="verification-disponibilites"
export default class extends Controller {

  // Cible le slim select des agents
  static targets = ["agents", "tools", "formAgents", "formTools", "debut_prevue", "debut_prevue_hour", "debut_prevue_minute", "fin_prevue", "fin_prevue_hour", "fin_prevue_minute"]

  static values = {
    interventionId: { type: Number, default: null }
  }

  // Variables d'instance pour début_prévue
  date_debut_prevue = null
  date_debut_prevue_hour = null
  date_debut_prevue_minute = null

  // Variables d'instance pour fin_prévue
  date_fin_prevue = null
  date_fin_prevue_hour = null
  date_fin_prevue_minute = null

  // Variable d'instance pour la liste des agent ids en conflit
  conflicting_agent_ids = null

  // Variable d'instance pour la liste des tool ids en conflit
  conflicting_tool_ids = null

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

    const agentObserver = new MutationObserver(mutations => {
      for (const mutation of mutations) {
        if (mutation.addedNodes.length > 0) {
          this.updateAgentTagsStyle()
        }
      }
    })

    agentObserver.observe(agentsContainer, { childList: true, subtree: true })



    const toolsContainer = this.formToolsTarget.querySelector(".ss-values")

    const toolObserver = new MutationObserver(mutations => {
      for (const mutation of mutations) {
        if (mutation.addedNodes.length > 0) {
          this.updateToolTagsStyle()
        }
      }
    })

    toolObserver.observe(toolsContainer, { childList: true, subtree: true })
  }

  // Fonction appelée à chaque changement d'une valeur des dates prévues
  verif(event) {

    this.updateDatesByEvent(event, event.target.value);

    this.change()

  }

  change() {
    // Initialisation de l'intervention_id
    let intervention_id = this.interventionIdValue || null

    // Initialisation des dates
    let date_début_prévue_to_send = this.createDate(this.date_debut_prevue, this.date_debut_prevue_hour, this.date_debut_prevue_minute)
    let date_fin_prévue_to_send = this.createDate(this.date_fin_prevue, this.date_fin_prevue_hour, this.date_fin_prevue_minute)

    // Initialitation de l'id de tous les agents
    const agentsOptions = this.agentsTarget.options
    let agent_ids = []
    for (let i = 1; i < agentsOptions.length; i++) {
      agent_ids.push(agentsOptions[i].value)
    }

    // Lancement de la requête pour récupérer les agents en conflit
    if (agent_ids.length > 0 && (date_début_prévue_to_send || date_fin_prévue_to_send)) {

      this.get_unavailable_elements(intervention_id, agent_ids, date_début_prévue_to_send, date_fin_prévue_to_send).then(
        elements => {
          this.conflicting_agent_ids = elements["agents"]
          if (this.conflicting_agent_ids) {
            this.updateAgentSelectedOptionsStyle();
            this.updateAgentTagsStyle()
          }
        }
      );
    }

    // Initialitation de l'id de tous les outils
    const toolsOptions = this.toolsTarget.options
    let tool_ids = []
    for (let i = 1; i < toolsOptions.length; i++) {
      tool_ids.push(toolsOptions[i].value)
    }

    // Lancement de la requête pour récupérer les outils en conflit
    if (tool_ids.length > 0 && (date_début_prévue_to_send || date_fin_prévue_to_send)) {

      this.get_unavailable_elements_by_tool(intervention_id, tool_ids, date_début_prévue_to_send, date_fin_prévue_to_send).then(
        elements => {
          this.conflicting_tool_ids = elements["tools"]
          console.log(elements["tools"])
          if (this.conflicting_tool_ids) {
            this.updateToolSelectedOptionsStyle();
            this.updateToolTagsStyle()
          }
        }
      );
    }
  }

  updateAgentSelectedOptionsStyle() {
    const agentsOptions = this.agentsTarget.options

    for (let i = 0; i < agentsOptions.length; i++) {
      let option_agent = agentsOptions[i]
      let option_agent_id = parseInt(option_agent.value)
      if (this.conflicting_agent_ids.includes(option_agent_id)) {
        option_agent.style = "background-color:red;"
      } else {
        option_agent.style = ""
      }
    }
  }

  updateAgentTagsStyle() {
    this.formAgentsTarget.querySelectorAll(".ss-values .ss-value").forEach(tag => {
      const agentName = tag.querySelector('.ss-value-text').textContent

      // Trouver l'option correspondante dans le select pour obtenir l'ID de l'agent
      const selectedOption = this.agentsTarget.slim.select.getSelectedOptions()
          .find(option => option.text === agentName)

      if (selectedOption) {
        const agentId = parseInt(selectedOption.value)

        // Vérifier si l'agent est dans la liste des agents en conflit
        if (this.conflicting_agent_ids && this.conflicting_agent_ids.includes(agentId)) {
          tag.style = "background-color:red;"
        } else {
          tag.style = ""
        }
      }
    })
  }

  updateToolSelectedOptionsStyle() {
    const toolOptions = this.toolsTarget.options

    for (let i = 0; i < toolOptions.length; i++) {
      let option_tool = toolOptions[i]
      let option_tool_id = parseInt(option_tool.value)
      if (this.conflicting_tool_ids.includes(option_tool_id)) {
        option_tool.style = "background-color:red;"
      } else {
        option_tool.style = ""
      }
    }
  }

  updateToolTagsStyle() {
    this.formToolsTarget.querySelectorAll(".ss-values .ss-value").forEach(tag => {
      const toolName = tag.querySelector('.ss-value-text').textContent

      // Trouver l'option correspondante dans le select pour obtenir l'ID de l'outil
      const selectedOption = this.toolsTarget.slim.select.getSelectedOptions()
        .find(option => option.text === toolName)

      if (selectedOption) {
        const toolId = parseInt(selectedOption.value)

        // Vérifier si l'outil est dans la liste des outils en conflit
        if (this.conflicting_tool_ids && this.conflicting_tool_ids.includes(toolId)) {
          tag.style = "background-color:red;"
        } else {
          tag.style = ""
        }
      }
    })
  }

  get_unavailable_elements(intervention_id, agent_ids, date_début_prévue_to_send, date_fin_prévue_to_send) {

    //console.log("Lancement de la requête")
    const url = this.getUrl(intervention_id, agent_ids, date_début_prévue_to_send, date_fin_prévue_to_send);

    //console.log("URL générée :", url);

    //TODO: Voir si garder le try-catch dans la fonction ou mettre le then directement
    return this.request_unavailable_elements(url)
  }

  get_unavailable_elements_by_tool(intervention_id, tool_ids, date_début_prévue_to_send, date_fin_prévue_to_send) {

    //console.log("Lancement de la requête")
    const url = this.getUrlByTool(intervention_id, tool_ids, date_début_prévue_to_send, date_fin_prévue_to_send);

    console.log("URL générée :", url);

    //TODO: Voir si garder le try-catch dans la fonction ou mettre le then directement
    return this.request_unavailable_elements(url)
  }

  getUrl(intervention_id, agent_ids, date_début_prévue_to_send, date_fin_prévue_to_send) {
    const begin_url = window.location.protocol + "//" + window.location.host

    const end_url = "/interventions/get_unavailable_elements?intervention_id=" + intervention_id + "&agents_ids=" + agent_ids + "&date_debut_prevue=" + date_début_prévue_to_send + "&date_fin_prevue=" + date_fin_prévue_to_send

    return begin_url + end_url;
  }
  
  getUrlByTool(intervention_id, tool_ids, date_début_prévue_to_send, date_fin_prévue_to_send) {
    const begin_url = window.location.protocol + "//" + window.location.host

    const end_url = "/interventions/get_unavailable_elements?intervention_id=" + intervention_id + "&tool_ids=" + tool_ids + "&date_debut_prevue=" + date_début_prévue_to_send + "&date_fin_prevue=" + date_fin_prévue_to_send

    return begin_url + end_url;
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

  createDate(date, hour, minute) {
    if (date && hour && minute) {
      return new Date(`${date}T${hour.padStart(2, '0')}:${minute.padStart(2, '0')}:00`).toISOString(); // ChatGPT
    } else {
      return null
    }
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
}
