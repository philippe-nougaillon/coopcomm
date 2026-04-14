import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle-role-info"
export default class extends Controller {
  static targets = ['role', 'localisation', 'prenom', 'tagLabel']

  initialize() {
    this.localisationTarget.style.display = 'none';
    this.change();
  }

  connect() {
    console.log("Hello, toggle-role-info !", this.element)
  }

  change() {
    var role = this.roleTarget.value;

    // On cible proprement les inputs pour éviter le piège des children[1]
    const addressInput = this.localisationTarget.querySelector('input[type="text"]');
    const prenomInput = this.prenomTarget.querySelector('input');

    if (role === 'agent' || role === 'manager' || role === '') {
      this.localisationTarget.style.display = 'none';
      if (addressInput) {
        addressInput.value = '';
        addressInput.required = false;
      }

      this.prenomTarget.style.display = 'block';
      if (prenomInput) prenomInput.required = true;
      this.updateTagLabel("Équipe");

    } else if (role === 'adhérent') {
      this.localisationTarget.style.display = 'block';
      if (addressInput) addressInput.required = true;

      this.prenomTarget.style.display = 'none';
      if (prenomInput) {
        prenomInput.required = false;
        prenomInput.value = '';
      }
      this.updateTagLabel("Secteur");
    }
  }

  updateTagLabel(texte) {
    if (this.hasTagLabelTarget) {
      this.tagLabelTarget.textContent = texte;
    }
  }
}