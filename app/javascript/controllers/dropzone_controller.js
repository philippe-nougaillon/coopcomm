import { Controller } from "@hotwired/stimulus"

// Zone de glisser-déposer générique et réutilisable autour d'un <input type="file">.
//
// L'input réel reste dans le formulaire (donc soumis normalement) ; on le masque
// et on lui injecte le fichier déposé via DataTransfer. Le type de fichier accepté
// est piloté par l'attribut `accept` de l'input — un fichier non conforme est
// refusé (drop comme sélecteur natif) avec un retour visuel.
//
// Cibles : input (requis), filename (libellé), error (message d'erreur).
// Classes : active (survol pendant un drag), neutral (bordure au repos),
//           valid (fichier accepté), invalid (fichier refusé).
//   La bordure neutre est retirée quand un état valid/invalid est posé : ainsi
//   une seule classe `border-color` est présente à la fois et la couleur
//   s'applique sans dépendre de l'ordre de cascade Tailwind.
// Valeur  : errorMessage (message custom ; défaut générique sinon).
export default class extends Controller {
  static targets = ["input", "filename", "error"]
  static classes = ["active", "neutral", "valid", "invalid"]
  static values = { errorMessage: String }

  connect() {
    this.defaultLabel = this.hasFilenameTarget ? this.filenameTarget.textContent.trim() : ""
  }

  open(event) {
    // Ignore le clic sur un lien interne (ex. « document actuel ») et le clic
    // synthétique remonté par input.click() (sinon : ouverture en boucle).
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

    const file = event.dataTransfer?.files?.[0]
    if (!file) return

    if (!this.accepts(file)) {
      this.markInvalid(file)
      return
    }

    // Reconstruit une liste de fichiers et l'assigne à l'input réel.
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    this.inputTarget.files = dataTransfer.files

    this.markValid(file)
  }

  // Sélecteur natif : l'attribut accept n'est pas garanti par tous les OS, on revalide.
  change() {
    const file = this.inputTarget.files[0]
    if (!file) {
      this.markNeutral()
    } else if (this.accepts(file)) {
      this.markValid(file)
    } else {
      this.inputTarget.value = ""
      this.markInvalid(file)
    }
  }

  // États visuels de la zone -------------------------------------------------

  markValid(file) {
    this.swapState({ add: this.validClasses, remove: [...this.invalidClasses, ...this.neutralClasses] })
    this.hideError()
    if (this.hasFilenameTarget) this.filenameTarget.textContent = file.name
  }

  markInvalid(file) {
    this.swapState({ add: this.invalidClasses, remove: [...this.validClasses, ...this.neutralClasses] })
    if (this.hasFilenameTarget) this.filenameTarget.textContent = this.defaultLabel
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = this.errorText(file)
      this.errorTarget.classList.remove("hidden")
    }
  }

  markNeutral() {
    this.swapState({ add: this.neutralClasses, remove: [...this.validClasses, ...this.invalidClasses] })
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
