import { Controller, Application } from "@hotwired/stimulus"
import TextareaAutogrow from 'stimulus-textarea-autogrow'

const application = Application.start()
application.register('textarea-autogrow', TextareaAutogrow)

// Connects to data-controller="textarea-autogrow"
export default class extends Controller {
  connect() {
    // console.log('Timeago controller connected')
  }
}