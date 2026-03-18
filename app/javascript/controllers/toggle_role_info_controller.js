import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle-agent-service"
export default class extends Controller {
  static targets = ['role', 'localisation', 'prenom']

  initialize() {
    this.localisationTarget.style.display = 'none';
    this.change();
  }

  connect() {
    console.log("Hello, toggle-agent!", this.element)
  }

  change() {
    var role = this.roleTarget;

    if (role.value == 'agent') {
      this.localisationTarget.style.display = 'none';
      this.localisationTarget.children[1].value = '';
      this.localisationTarget.children[1].required = false;
      this.prenomTarget.style.display = 'block';
      this.prenomTarget.children[1].required = true;
    } else if (role.value == 'adhérent') {
      this.localisationTarget.style.display = 'block';
      this.localisationTarget.children[1].required = true;
      this.prenomTarget.style.display = 'none';
      this.prenomTarget.children[1].required = false;
      this.prenomTarget.children[1].value = '';
    } else if (role.value == 'manager') {
      // console.log(this.serviceTarget.children[1].selectedIndex)
      this.localisationTarget.style.display = 'none';
      this.localisationTarget.children[1].value = '';
      this.localisationTarget.children[1].required = false;
      this.prenomTarget.style.display = 'block';
      this.prenomTarget.children[1].required = true;
    } else {
      // console.log(this.serviceTarget.children[1].selectedIndex)
      this.localisationTarget.style.display = 'none';
      this.localisationTarget.children[1].value = '';
      this.localisationTarget.children[1].required = false;
      this.prenomTarget.style.display = 'block';
      this.prenomTarget.children[1].required = true;
    }
  }
}
