import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="toggle-role-info"
export default class extends Controller {
  static targets = ["role", "localisation", "prenom"];

  initialize() {
    this.localisationTarget.style.display = "none";
    this.change();
  }

  connect() {
    console.log("Hello, toggle-role-info !", this.element);
  }

  change() {
    var role = this.roleTarget.value;

    const addressInput =
      this.localisationTarget.querySelector('input[type="text"]');
    const prenomInput = this.prenomTarget.querySelector("input");

    if (
      role === "agent" ||
      role === "manager" ||
      role === "administrateur" ||
      role === ""
    ) {
      this.localisationTarget.style.display = "none";
      if (addressInput) {
        addressInput.value = "";
        addressInput.required = false;
      }

      this.prenomTarget.style.display = "block";
      if (prenomInput) prenomInput.required = true;
    } else if (role === "adhérent") {
      this.localisationTarget.style.display = "block";
      if (addressInput) addressInput.required = true;

      this.prenomTarget.style.display = "none";
      if (prenomInput) {
        prenomInput.required = false;
        prenomInput.value = "";
      }
    }
  }
}
