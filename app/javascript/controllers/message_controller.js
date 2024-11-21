import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="message"
export default class extends Controller {
  static targets = ['message']
  connect() {
    console.log('Message controller connected')
  }

  async submit(event) {
    event.preventDefault(); // Empêche le rechargement de la page

    const form = event.target;
    const url = form.action;
    const formData = new FormData(form);

    try {
      const response = await fetch(url, {
        method: "POST",
        body: formData,
        headers: { "X-Requested-With": "XMLHttpRequest" },
      });

      if (response.ok) {
        const result = await response.json();
        // console.log(result.message); // Log du message de succès

        // Vider le champ message
        this.messageTarget.value = "";

        // Focus sur le champ message
        this.messageTarget.focus();
      } else {
        const errorResult = await response.json();
        console.error("Erreur :", errorResult.errors.join(", "));
        alert(`Erreur : ${errorResult.errors.join(", ")}`); // Affiche les erreurs
      }
    } catch (error) {
      console.error("Erreur réseau :", error);
      alert("Une erreur réseau est survenue. Veuillez réessayer.");
    }
  }
}
