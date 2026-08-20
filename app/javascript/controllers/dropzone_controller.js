import { Controller } from "@hotwired/stimulus"

// Zone de glisser-déposer autour d'un <input type="file"> masqué, qui reste dans
// le formulaire : les fichiers déposés lui sont injectés via DataTransfer, en
// respectant ses attributs `multiple` et `accept`.
//
// Cibles : input (requis), filename, error, count.
// Classes : active, neutral, valid, invalid — neutral est retirée dès qu'un état
// valid/invalid est posé, pour ne jamais avoir deux `border-color` en cascade.
// Valeurs : errorMessage, sizeMessage, maxSize, dropLabel.
export default class extends Controller {
  static targets = ["input", "filename", "error", "count","fileList"]
  static classes = ["active", "neutral", "valid", "invalid"]
  static values = { errorMessage: String, sizeMessage: String, maxSize: Number, dropLabel: String }

  connect() {
    this.defaultLabel = this.hasFilenameTarget ? this.filenameTarget.textContent.trim() : ""

    this.form = this.element.closest("form")
    this.boundBloquerSiRefus = (event) => this.bloquerSiRefus(event)
    if (this.form) this.form.addEventListener("submit", this.boundBloquerSiRefus)
  }

  disconnect() {
    if (this.form) this.form.removeEventListener("submit", this.boundBloquerSiRefus)
  }

  // Le fichier refusé est retiré de l'input : sans ce garde le formulaire
  // partirait sans lui et l'enregistrement réussirait, pièce jointe perdue en
  // silence. Turbo n'envoie rien quand la soumission est déjà empêchée.
  bloquerSiRefus(event) {
    if (this.element.dataset.dropzoneState !== "error") return

    event.preventDefault()
    this.element.scrollIntoView({ block: "center" })
  }

  open(event) {
    // Ignore le clic sur un lien interne et celui remonté par input.click() (boucle).
    if (event.target.closest("a")) return
    if (event.target === this.inputTarget) return
    this.inputTarget.click()
  }

  highlight(event) {
    event.preventDefault()
    if (this.element.dataset.dropzoneDragging) return

    this.element.dataset.dropzoneDragging = "true"
    this.activeClasses.forEach(c => this.element.classList.add(c))

    if (this.hasFilenameTarget && this.dropLabelValue) {
      this.labelBeforeDrag = this.filenameTarget.textContent
      this.filenameTarget.textContent = this.dropLabelValue
      this.countBeforeDrag = this.countText()
      this.setCount("")
    }
  }

  // dragleave se déclenche aussi en passant sur un enfant de la zone : sans ce
  // filtre, l'effet clignote pendant tout le survol.
  unhighlight(event) {
    if (event) {
      event.preventDefault()
      if (event.relatedTarget && this.element.contains(event.relatedTarget)) return
    }

    delete this.element.dataset.dropzoneDragging
    this.activeClasses.forEach(c => this.element.classList.remove(c))

    if (this.hasFilenameTarget && this.labelBeforeDrag !== undefined) {
      this.filenameTarget.textContent = this.labelBeforeDrag
      this.labelBeforeDrag = undefined
      this.setCount(this.countBeforeDrag || "")
      this.countBeforeDrag = undefined
    }
  }

  drop(event) {
    event.preventDefault()
    this.unhighlight()

    let files = Array.from(event.dataTransfer?.files || [])
    if (this.inputTarget.multiple === false) files = files.slice(0, 1)
    if (files.length === 0) return

    const rejected = files.find(file => this.motifDeRefus(file))
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
    const rejected = files.find(file => this.motifDeRefus(file))
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
    this.setCount(`${files.length} fichier${files.length > 1 ? "s" : ""} sélectionné${files.length > 1 ? "s" : ""}`)
    this.renderFileList(files)
  }

  renderFileList(files) {
    if (!this.hasFileListTarget) return
    this.fileListTarget.innerHTML = files.map((file, i) => `
      <li class="flex items-center gap-3 p-2 border border-slate-200 rounded-lg" data-index="${i}">
        <span class="text-sm flex-1 truncate">${file.name}</span>
        <span class="text-xs text-slate-400">${(file.size / 1024).toFixed(1)} KB</span>
        <button type="button" data-action="dropzone#removeFile" data-index="${i}" class="text-slate-400 hover:text-error">✕</button>
      </li>
    `).join("")
    this.fileListTarget.classList.remove("hidden")
    this.fileListTarget.classList.add("flex")
  }

  removeFile(event) {
    const index = Number(event.currentTarget.dataset.index)
    const dt = new DataTransfer()
    Array.from(this.inputTarget.files).forEach((file, i) => { if (i !== index) dt.items.add(file) })
    this.inputTarget.files = dt.files
    this.change()
  }

  markInvalid(file) {
    this.swapState({ add: this.invalidClasses, remove: [...this.validClasses, ...this.neutralClasses] })
    this.element.dataset.dropzoneState = "error" // marqueur d'état inerte (cf. markValid)
    if (this.hasFilenameTarget) this.filenameTarget.textContent = this.defaultLabel
    this.setCount("")
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
    this.setCount("")
  }

  setCount(texte) {
    if (!this.hasCountTarget) return
    this.countTarget.textContent = texte
    this.countTarget.classList.toggle("hidden", texte === "")
  }

  countText() {
    return this.hasCountTarget ? this.countTarget.textContent : ""
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
    if (this.motifDeRefus(file) === "taille") {
      return this.sizeMessageValue || `« ${file.name} » dépasse la taille maximale.`
    }
    if (this.errorMessageValue) return this.errorMessageValue
    return `« ${file.name} » n'est pas dans un format accepté.`
  }

  // Doublon assumé de la validation du modèle : évite d'envoyer 20 Mo pour rien.
  motifDeRefus(file) {
    if (!this.accepts(file)) return "format"
    if (this.hasMaxSizeValue && this.maxSizeValue > 0 && file.size > this.maxSizeValue) return "taille"
    return null
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
