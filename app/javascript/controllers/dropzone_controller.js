import { Controller } from "@hotwired/stimulus"

// Zone de glisser-déposer autour d'un <input type="file"> masqué, qui reste dans
// le formulaire : les fichiers déposés lui sont injectés via DataTransfer, en
// respectant ses attributs `multiple` et `accept`.
//
// Cibles : input (requis), filename, error.
// Classes : active, neutral, valid, invalid — neutral est retirée dès qu'un état
// valid/invalid est posé, pour ne jamais avoir deux `border-color` en cascade.
// Valeur : errorMessage.
export default class extends Controller {
  static targets = ["input", "filename", "error"]
  static classes = ["active", "neutral", "valid", "invalid"]
  static values = { errorMessage: String }

  connect() {
    this.defaultLabel = this.hasFilenameTarget ? this.filenameTarget.textContent.trim() : ""
  }

  open(event) {
    // Ignore le clic sur un lien interne et celui remonté par input.click() (boucle).
    if (event.target.closest("a")) return
    if (event.target === this.inputTarget) return
    this.inputTarget.click()
  }

  highlight(event) {
    event.preventDefault()
    this.activeClasses.forEach(c => this.element.classList.add(c))
  }

  unhighlight(event) {
    if (event) event.preventDefault()
    this.activeClasses.forEach(c => this.element.classList.remove(c))
  }

  drop(event) {
    event.preventDefault()
    this.unhighlight()

    let files = Array.from(event.dataTransfer?.files || [])
    if (this.inputTarget.multiple === false) files = files.slice(0, 1)
    if (files.length === 0) return

    const rejected = files.find(file => !this.accepts(file))
    if (rejected) {
      this.markInvalid(rejected)
      return
    }

    const dataTransfer = new DataTransfer()
    files.forEach(file => dataTransfer.items.add(file))
    this.inputTarget.files = dataTransfer.files

    this.markValid(files)
  }

  // L'attribut accept n'est pas garanti par tous les OS, on revalide.
  change() {
    const files = Array.from(this.inputTarget.files)
    const rejected = files.find(file => !this.accepts(file))
    if (files.length === 0) {
      this.markNeutral()
    } else if (rejected) {
      this.inputTarget.value = ""
      this.markInvalid(rejected)
    } else {
      this.markValid(files)
    }
  }

  // États visuels de la zone -------------------------------------------------

  markValid(files) {
    this.swapState({ add: this.validClasses, remove: [...this.invalidClasses, ...this.neutralClasses] })
    // Marqueur inerte : point d'ancrage des tests système, stable au renommage CSS.
    this.element.dataset.dropzoneState = "success"
    this.hideError()
    if (this.hasFilenameTarget) this.filenameTarget.textContent = files.map(file => file.name).join(", ")
  }

  markInvalid(file) {
    this.swapState({ add: this.invalidClasses, remove: [...this.validClasses, ...this.neutralClasses] })
    this.element.dataset.dropzoneState = "error" // marqueur d'état inerte (cf. markValid)
    if (this.hasFilenameTarget) this.filenameTarget.textContent = this.defaultLabel
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = this.errorText(file)
      this.errorTarget.classList.remove("hidden")
    }
  }

  markNeutral() {
    this.swapState({ add: this.neutralClasses, remove: [...this.validClasses, ...this.invalidClasses] })
    this.element.dataset.dropzoneState = "neutral" // marqueur d'état inerte (cf. markValid)
    this.hideError()
    if (this.hasFilenameTarget) this.filenameTarget.textContent = this.defaultLabel
  }

  swapState({ add, remove }) {
    remove.forEach(c => this.element.classList.remove(c))
    add.forEach(c => this.element.classList.add(c))
  }

  hideError() {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }

  errorText(file) {
    if (this.errorMessageValue) return this.errorMessageValue
    return `« ${file.name} » n'est pas dans un format accepté.`
  }

  // Respecte l'attribut accept de l'input (ex. ".pdf", "image/*", ".pdf,.docx").
  accepts(file) {
    const accept = this.inputTarget.getAttribute("accept")
    if (!accept) return true

    return accept.split(",").map(s => s.trim()).filter(Boolean).some(rule => {
      if (rule.startsWith(".")) return file.name.toLowerCase().endsWith(rule.toLowerCase())
      if (rule.endsWith("/*")) return file.type.startsWith(rule.slice(0, -1))
      return file.type === rule
    })
  }
}
