import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["adherent", "service"]
  static values = { url: String }

  updateServices() {
    const adherentId = this.adherentTarget.value

    if (!adherentId) {
      this.populateSelect([])
      return
    }

    // Requête vers notre nouvelle action Rails
    fetch(`${this.urlValue}?adherent_id=${adherentId}`, {
      headers: { "Accept": "application/json" }
    })
      .then(response => response.json())
      .then(data => this.populateSelect(data))
  }

  populateSelect(services) {
    const select = this.serviceTarget

    // 1. On met à jour le select natif (toujours utile pour le formulaire)
    select.innerHTML = "<option value=''></option>"
    services.forEach(service => {
      const option = document.createElement("option")
      option.value = service.id
      option.text = service.nom
      select.appendChild(option)
    })

    // 2. On prépare les données au format exigé par l'API de Slim-Select
    const slimData = [{ text: '', value: '', placeholder: true }]
    services.forEach(service => {
      slimData.push({ text: service.nom, value: service.id })
    })

    // Règle métier : S'il y a un seul service, on le sélectionne
    if (services.length === 1) {
      slimData[1].selected = true
      select.value = services[0].id // On met aussi à jour le select natif
    }

    // 3. LA MAGIE SLIM-SELECT
    // Il faut passer ces nouvelles données à l'instance de Slim-Select.

    // CAS A : Si vous êtes sur SlimSelect v1 (l'instance est souvent sur l'élément)
    if (select.slim) {
      select.slim.setData(slimData)
    }
    // CAS B : Méthode force brute si vous n'avez pas accès à l'instance
    else {
      // On cherche l'interface générée par SlimSelect juste après notre vrai select
      const slimWrapper = select.nextElementSibling
      if (slimWrapper && slimWrapper.classList.contains('ss-main')) {
        slimWrapper.remove() // On détruit l'ancien visuel
        select.style.display = 'block' // On rend le select visible temporairement
        new SlimSelect({ select: select }) // On relance SlimSelect
      }
    }
  }
}