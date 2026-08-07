// app/javascript/controllers/slim_select_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    // Paramètres communs
    const commonSettings = {
      placeholderText: this.element.dataset.placeholder || '',
      searchPlaceholder: 'Rechercher',
      searchText: 'Pas de résultat',
      searchingText: 'Recherche...',
      allowDeselect: true,
    }

    // Gestion des exceptions "addable"
    let specificSettings = {}
    let specificEvents = {}

    if (this.element.dataset.addable === 'true') {
      specificSettings = {
        addableText: 'Appuyez sur "Entrer" pour ajouter {value}',
      }
      specificEvents = {
        addable: (value) => value
      }
    }

    // Le videur anti-désélection
    const beforeChangeFunction = (newVal, oldVal) => {
      // On cherche si ce select possède des options obligatoires (grâce au Helper Rails)
      const mandatoryOptions = Array.from(this.element.querySelectorAll('option[data-mandatory="true"]'))

      if (mandatoryOptions.length > 0) {
        const mandatoryValues = mandatoryOptions.map(opt => String(opt.value))

        // newVal peut être un tableau (select multiple) ou un objet seul (select simple)
        const selectedValues = Array.isArray(newVal) ? newVal.map(item => String(item.value)) : [String(newVal.value)]

        // On vérifie que TOUTES les valeurs obligatoires sont bien présentes dans la tentative de l'utilisateur
        const allMandatoryPresent = mandatoryValues.every(val => selectedValues.includes(val))

        if (!allMandatoryPresent) {
          // Si une valeur obligatoire manque, on annule silencieusement le clic de l'utilisateur
          return false
        }
      }
      return true // Sinon, on laisse passer
    }

    // On fusionne les événements existants avec ce nouveau videur
    const events = {
      ...specificEvents,
      beforeChange: beforeChangeFunction
    }

    // Initialisation
    this.select = new SlimSelect({
      select: this.element,
      settings: { ...commonSettings, ...specificSettings },
      events: events
    })

    // Ton fix pour les champs requis
    if (this.element.hasAttribute('required')) {
      this.applyRequiredFix()
    }
  }

  applyRequiredFix() {
    if (this.element.parentElement) {
      this.element.parentElement.style.position = 'relative'
    }

    this.element.removeAttribute('aria-hidden')
    this.element.setAttribute('tabindex', '-1')

    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === "attributes" && mutation.attributeName === "aria-hidden") {
          if (this.element.hasAttribute('aria-hidden')) {
            this.element.removeAttribute('aria-hidden')
          }
        }
      })
    })

    this.observer.observe(this.element, { attributes: true, attributeFilter: ['aria-hidden'] })

    this.handleFocus = this.handleFocus.bind(this)
    this.handleRemoveError = this.handleRemoveError.bind(this)

    this.element.addEventListener('focus', this.handleFocus)
    this.element.addEventListener('blur', this.handleRemoveError)
    this.element.addEventListener('change', this.handleRemoveError)
  }

  handleFocus() {
    const wrapper = this.element.nextElementSibling
    if (wrapper && wrapper.classList.contains('ss-main')) {
      wrapper.classList.add('ss-error-native')
    }
  }

  handleRemoveError() {
    const wrapper = this.element.nextElementSibling
    if (wrapper) wrapper.classList.remove('ss-error-native')
  }

  // Nettoyage géré par Stimulus (remplace turbo:before-cache)
  disconnect() {
    if (this.observer) this.observer.disconnect()

    if (this.element.hasAttribute('required')) {
      this.element.removeEventListener('focus', this.handleFocus)
      this.element.removeEventListener('blur', this.handleRemoveError)
      this.element.removeEventListener('change', this.handleRemoveError)
    }

    if (this.select) {
      this.select.destroy()
    }
  }
}