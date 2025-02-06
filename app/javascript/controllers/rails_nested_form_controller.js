import { Controller, Application } from '@hotwired/stimulus'
import RailsNestedForm from '@stimulus-components/rails-nested-form'

const application = Application.start()
application.register('nested-form', RailsNestedForm)

// Connects to data-controller="nested-form"
export default class extends Controller {
  connect() {
    // console.log('NestedForm controller connected')
  }
}
