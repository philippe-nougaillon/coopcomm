import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["adherent", "service", "agents"]
  static values = { url: String, agentsUrl: String }

  updateServices() {
    const adherentId = this.adherentTarget.value

    if (!adherentId) {
      this.populateSelect([])
      // Le service a été vidé : on recharge la liste des agents en conséquence.
      this.updateAgents()
      return
    }

    // Requête vers notre nouvelle action Rails
    fetch(`${this.urlValue}?adherent_id=${adherentId}`, {
      headers: { "Accept": "application/json" }
    })
      .then(response => response.json())
      .then(data => {
        this.populateSelect(data)
        // Le service vient d'être (re)peuplé : on aligne la liste des agents.
        this.updateAgents()
      })
  }

  // Recharge la liste PLATE des agents selon le service sélectionné.
  // Sans service, l'endpoint renvoie tous les agents du périmètre courant.
  updateAgents() {
    if (!this.hasAgentsTarget || !this.hasAgentsUrlValue) return

    const serviceId = this.hasServiceTarget ? this.serviceTarget.value : ""
    const url = serviceId
      ? `${this.agentsUrlValue}?service_id=${encodeURIComponent(serviceId)}`
      : this.agentsUrlValue

    fetch(url, { headers: { "Accept": "application/json" } })
      .then(response => response.json())
      .then(agents => this.populateAgents(agents))
  }

  populateAgents(agents) {
    const select = this.agentsTarget

    // On conserve la sélection courante qui reste valide (∩ nouveaux agents)
    // ainsi que les options obligatoires (data-mandatory) le cas échéant.
    const previouslySelected = new Set(
      Array.from(select.selectedOptions).map(o => String(o.value))
    )
    const mandatoryValues = new Set(
      Array.from(select.querySelectorAll('option[data-mandatory="true"]')).map(o => String(o.value))
    )

    const data = agents.map(agent => {
      const value = String(agent.id)
      const item = {
        text: agent.nom,
        value: value,
        selected: previouslySelected.has(value) || mandatoryValues.has(value)
      }
      if (mandatoryValues.has(value)) item.data = { mandatory: "true" }
      return item
    })

    // On met à jour via l'instance SlimSelect existante (sans la recréer) pour
    // préserver sa logique anti-désélection (beforeChange). Repli sur le select
    // natif si l'instance n'est pas disponible.
    const slim = this.slimSelectDe(this.agentsTarget)
    if (slim) {
      slim.setData(data)
    } else {
      select.innerHTML = ""
      data.forEach(d => {
        const option = document.createElement("option")
        option.value = d.value
        option.text = d.text
        if (d.selected) option.selected = true
        if (d.data && d.data.mandatory) option.dataset.mandatory = "true"
        select.appendChild(option)
      })
    }

    // Filet de sécurité : garantir l'attribut data-mandatory sur le select natif
    // quelle que soit la façon dont SlimSelect a régénéré les options.
    mandatoryValues.forEach(value => {
      const option = Array.from(select.options).find(o => String(o.value) === value)
      if (option) option.dataset.mandatory = "true"
    })

    // Recalcul immédiat : temps passé + matériel/agents en conflit de dispo.
    select.dispatchEvent(new Event("change", { bubbles: true }))
    this.refreshAvailability()
  }

  // Relance la vérification des disponibilités (conflits) tout de suite, sans
  // attendre une modification de date. Le contrôleur est porté par le <form>.
  refreshAvailability() {
    const form = this.agentsTarget.closest("form")
    if (!form) return

    const verif = this.application.getControllerForElementAndIdentifier(form, "verification-disponibilites")
    if (verif) verif.change()
  }

  slimSelectDe(select) {
    const controller = this.application.getControllerForElementAndIdentifier(select, "slim-select")
    return controller ? controller.select : null
  }

  populateSelect(services) {
    const select = this.serviceTarget

    select.innerHTML = "<option value=''></option>"
    const slimData = [{ text: '', value: '', placeholder: true }]

    services.forEach(service => {
      const option = document.createElement("option")
      option.value = service.id
      option.text = service.nom
      select.appendChild(option)
      slimData.push({ text: service.nom, value: service.id })
    })

    // Un seul service possible : il est présélectionné.
    if (services.length === 1) {
      slimData[1].selected = true
      select.value = services[0].id
    }

    const slim = this.slimSelectDe(select)
    if (slim) slim.setData(slimData)
  }
}
