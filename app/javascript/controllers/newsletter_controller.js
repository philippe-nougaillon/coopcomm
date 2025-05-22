import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="newsletter"
export default class extends Controller {

  static targets = ['result', 'email']

  print_result() {
    const email = this.emailTarget

    if (email.checkValidity()) {
      this.resultTarget.src = `/newsletters/new?email=${email.value}`;
    }
  }

}
