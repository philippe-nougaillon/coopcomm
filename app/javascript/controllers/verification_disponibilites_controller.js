import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="verification-disponibilites"
export default class extends Controller {

  // Cible le slim select des agents
  static targets = [
    "agents", "tools", 
    "formAgents", "formTools", 
    "debut_prevue", "debut_prevue_hour", "debut_prevue_minute", 
    "fin_prevue", "fin_prevue_hour", "fin_prevue_minute"
  ]

  static values = {
    interventionId: { type: Number, default: null }
  }

  // Variable d'instance pour la liste des agent ids en conflit
  conflicting_agent_ids = []

  // Variable d'instance pour la liste des tool ids en conflit
  conflicting_tool_ids = []

  initialize() {
    this.updateDatesFromInputs()
  }

  connect() {
    // Initialise un observeur sur les agents pour mettre en rouge le tags si l'agent est en conflit. Seul moyen tant qu'il y a slim select.
    this.observeSlimSelectTags(this.formAgentsTarget, this.updateAgentTagsStyle.bind(this))
    this.observeSlimSelectTags(this.formToolsTarget, this.updateToolTagsStyle.bind(this))

    this.change()
  }

  // Initialise un observeur pour détecter les ajouts dans la liste des valeurs sélectionnées
  observeSlimSelectTags(container, callback) {
    const observer = new MutationObserver(mutations => {
      if (mutations.some(m => m.addedNodes.length > 0)) callback()
    })
    observer.observe(container.querySelector(".ss-values"), { childList: true, subtree: true })
  }

  // Fonction appelée à chaque changement d'une valeur des dates prévues
  verif(event) {
    this.updateDateValue(event.target)
    this.change()
  }

  change() {
    // Initialisation de l'intervention_id
    const intervention_id = this.interventionIdValue || null

    // Initialisation des dates
    const date_debut = this.createDate(this.date_debut_prevue, this.date_debut_prevue_hour, this.date_debut_prevue_minute)
    const date_fin = this.createDate(this.date_fin_prevue, this.date_fin_prevue_hour, this.date_fin_prevue_minute)

    // Initialitation de l'id de tous les agents
    let options = [...this.agentsTarget.options]

    let hasIncludeBlank = options[0]?.value === ""

    // Permet une flexibilité du formulaire pour inclure ou non une case vide
    const agent_ids = hasIncludeBlank
      ? options.slice(1).map(o => o.value)
      : options.map(o => o.value)

    // Initialitation de l'id de tous les outils
    options = [...this.toolsTarget.options]

    hasIncludeBlank = options[0]?.value === ""

    const tool_ids = hasIncludeBlank
      ? options.slice(1).map(o => o.value)
      : options.map(o => o.value)

    // Lancement de la requête pour récupérer les outils en conflit
    if ((agent_ids.length || tool_ids.length) && (date_debut || date_fin)) {
      const url = this.getUnifiedUrl(intervention_id, agent_ids, tool_ids, date_debut, date_fin)

      this.fetchUnavailableElements(url).then(data => {
        if (!data) return
        this.conflicting_agent_ids = data.agents || []
        this.conflicting_tool_ids = data.tools || []

        this.updateSelectStyles(this.agentsTarget, this.conflicting_agent_ids)
        this.updateSelectStyles(this.toolsTarget, this.conflicting_tool_ids)

        this.updateAgentTagsStyle()
        this.updateToolTagsStyle()
      })
    }
  }

  updateSelectStyles(selectElement, conflictIds) {
    [...selectElement.options].forEach(option => {
      const id = parseInt(option.value)
      option.style = conflictIds.includes(id) ? "background-color:red;" : ""
    })
    
  }

  updateTagsStyle(container, select, conflictIds) {
    container.querySelectorAll(".ss-value").forEach(tag => {
      const name = tag.querySelector(".ss-value-text")?.textContent?.trim()

      // Recherche de l'option dans le select qui a le même texte
      const matchingOption = [...select.options].find(opt => opt.text.trim() === name)
      const id = matchingOption ? parseInt(matchingOption.value) : null

      tag.style.backgroundColor = conflictIds.includes(id) ? "red" : ""
    })
  }

  updateAgentTagsStyle() {
    this.updateTagsStyle(this.formAgentsTarget, this.agentsTarget, this.conflicting_agent_ids)
  }

  updateToolTagsStyle() {
    this.updateTagsStyle(this.formToolsTarget, this.toolsTarget, this.conflicting_tool_ids)
  }

  getUnifiedUrl(intervention_id, agent_ids, tool_ids, date_debut, date_fin) {
    const base = `${window.location.protocol}//${window.location.host}`
    const params = new URLSearchParams({
      intervention_id,
      agents_ids: agent_ids,
      tool_ids: tool_ids,
      date_debut_prevue: date_debut,
      date_fin_prevue: date_fin
    })
    return `${base}/interventions/get_unavailable_elements?${params}`
  }

  async fetchUnavailableElements(url) {
    try {
      const response = await fetch(url, {
        method: "GET",
        headers: { "X-Requested-With": "XMLHttpRequest" }
      })

      if (!response.ok) {
        const error = await response.json()
        console.error("Erreur :", error.errors?.join(", "))
        alert(`Erreur : ${error.errors?.join(", ")}`)
        return null
      }

      return await response.json()
    } catch (err) {
      console.error("Erreur réseau :", err)
      alert("Une erreur réseau est survenue. Veuillez réessayer.")
    }
  }

  createDate(date, hour, minute) {
    if (date && hour && minute) {
      return new Date(`${date}T${hour.padStart(2, '0')}:${minute.padStart(2, '0')}:00`).toISOString()
    }
    return null
  }

  updateDatesFromInputs() {
    if (this.debut_prevueTarget.value) this.date_debut_prevue = this.debut_prevueTarget.value
    if (this.debut_prevue_hourTarget.value) this.date_debut_prevue_hour = this.debut_prevue_hourTarget.value
    if (this.debut_prevue_minuteTarget.value) this.date_debut_prevue_minute = this.debut_prevue_minuteTarget.value
    if (this.fin_prevueTarget.value) this.date_fin_prevue = this.fin_prevueTarget.value
    if (this.fin_prevue_hourTarget.value) this.date_fin_prevue_hour = this.fin_prevue_hourTarget.value
    if (this.fin_prevue_minuteTarget.value) this.date_fin_prevue_minute = this.fin_prevue_minuteTarget.value
  }

  updateDateValue(target) {
    switch (target.id) {
      case "intervention_début_prévue":
        this.date_debut_prevue = target.value
        break
      case "intervention_début_prévue_hour":
        this.date_debut_prevue_hour = target.value
        break
      case "intervention_début_prévue_minute":
        this.date_debut_prevue_minute = target.value
        break
      case "intervention_fin_prévue":
        this.date_fin_prevue = target.value
        break
      case "intervention_fin_prévue_hour":
        this.date_fin_prevue_hour = target.value
        break
      case "intervention_fin_prévue_minute":
        this.date_fin_prevue_minute = target.value
        break
    }
  }
}
