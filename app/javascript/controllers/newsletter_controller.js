import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="newsletter"
export default class extends Controller {

  static targets = ['result', 'email']

  print_result() {
    const email = this.emailTarget.value

    if(email){
      this.resultTarget.src = `/newsletter/send_email_newsletter?email=${email}`;
    }
  }

}
