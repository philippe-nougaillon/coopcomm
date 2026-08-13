import { Controller, Application } from "@hotwired/stimulus"
import Notification from 'stimulus-notification'

const application = Application.start()
application.register('notification', Notification)

// Connects to data-controller="notification"
export default class extends Notification {
  pause() {
    clearTimeout(this.timeout)
  }

  resume() {
    this.timeout = setTimeout(() => this.hide(), 2000) // Concede 2s extra al quitar el ratón
  }
}