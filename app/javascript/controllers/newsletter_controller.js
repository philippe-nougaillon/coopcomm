import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="newsletter"
export default class extends Controller {

  static targets = ['result', 'email']

  print_result() {
    const email = this.emailTarget

    if (email.checkValidity()) {
      this.resultTarget.src = `/newsletters/send_email_newsletter?email=${email.value}`;
      email.value = ""
      email.closest("form").setAttribute("novalidate", true)
    }
  }

}
