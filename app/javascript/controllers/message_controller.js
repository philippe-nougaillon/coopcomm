import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="message"
export default class extends Controller {
  static targets = ['message','submit', 'user']
  connect() {
    console.log('Message controller connected')
  }

  delete_message() {
    if (this.userTarget.value !== "") {
      this.messageTarget.value = "";
    }
  }
}
