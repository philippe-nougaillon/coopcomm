// app/javascript/controllers/slim_select_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 1. Tes paramètres communs (Traductions)
    const commonSettings = {
      placeholderText: '',
      searchPlaceholder: 'Rechercher',
      searchText: 'Pas de résultat',
      searchingText: 'Recherche...',
      allowDeselect: true,
    }

    // 2. Gestion des exceptions "addable" (création de tags)
    let specificSettings = {}
    let specificEvents = {}

    const addableIds = ['intervention_tags_manager', 'user_tag_list']

    if (addableIds.includes(this.element.id)) {
      specificSettings = {
        addableText: 'Appuyez sur "Entrer" pour ajouter {value}',
      }
      specificEvents = {
        addable: (value) => value
      }
    }

    // 3. Initialisation de SlimSelect avec fusion des paramètres
    this.select = new SlimSelect({
      select: this.element,
      settings: { ...commonSettings, ...specificSettings },
      events: specificEvents
    })

    // 4. Ton fix pour les champs requis
    if (this.element.hasAttribute('required')) {
      this.applyRequiredFix()
    }
  }

  // ... (Garde exactement les mêmes fonctions applyRequiredFix, handleFocus, et handleRemoveError qu'avant) ...
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

  // 5. Nettoyage géré par Stimulus (remplace ton ancien turbo:before-cache)
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