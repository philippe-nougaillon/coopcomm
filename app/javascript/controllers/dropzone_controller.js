import { Controller } from "@hotwired/stimulus"

// Zone de glisser-déposer autour d'un <input type="file"> masqué, qui reste dans
// le formulaire : les fichiers déposés lui sont injectés via DataTransfer, en
// respectant ses attributs `multiple` et `accept`.
//
// Cibles : box (zone colorée cliquable), input (requis), filename, error, count, fileList.
// La liste de fichiers (fileList) est un frère de `box`, pas un descendant : les
// clics sur ses boutons ne doivent pas rouvrir le sélecteur de fichiers.
// Classes : active, neutral, valid, invalid — appliquées à `box`, pas à l'élément
// racine du contrôleur.
// Valeurs : errorMessage, sizeMessage, maxSize, dropLabel.
export default class extends Controller {
  static targets = ["box", "input", "filename", "error", "count", "fileList"]
  static classes = ["active", "neutral", "valid", "invalid"]
  static values = { errorMessage: String, sizeMessage: String, maxSize: Number, dropLabel: String }

  connect() {
    this.defaultLabel = this.hasFilenameTarget ? this.filenameTarget.textContent.trim() : ""
    this.objectUrls = []

    this.form = this.element.closest("form")
    this.boundBloquerSiRefus = (event) => this.bloquerSiRefus(event)
    if (this.form) this.form.addEventListener("submit", this.boundBloquerSiRefus)
  }

  disconnect() {
    if (this.form) this.form.removeEventListener("submit", this.boundBloquerSiRefus)
    this.revokeObjectUrls()
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
    this.activeClasses.forEach(c => this.boxTarget.classList.add(c))

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
      if (event.relatedTarget && this.boxTarget.contains(event.relatedTarget)) return
    }

    delete this.element.dataset.dropzoneDragging
    this.activeClasses.forEach(c => this.boxTarget.classList.remove(c))

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

  // Retire un fichier de la sélection (bouton ✕ de la liste) puis revalide.
  removeFile(event) {
    const index = Number(event.currentTarget.dataset.index)
    const dt = new DataTransfer()
    Array.from(this.inputTarget.files).forEach((file, i) => {
      if (i !== index) dt.items.add(file)
    })
    this.inputTarget.files = dt.files
    this.change()
  }

  // États visuels de la zone -------------------------------------------------

  markValid(files) {
    this.swapState({ add: this.validClasses, remove: [...this.invalidClasses, ...this.neutralClasses] })
    // Marqueur inerte : point d'ancrage des tests système, stable au renommage CSS.
    this.element.dataset.dropzoneState = "success"
    this.hideError()
    // Si une liste détaillée existe, elle remplace l'affichage des noms dans filename.
    if (this.hasFilenameTarget && !this.hasFileListTarget) {
      this.filenameTarget.textContent = files.map(file => file.name).join(", ")
    }
    this.setCount(`${files.length} fichier${files.length > 1 ? "s" : ""} sélectionné${files.length > 1 ? "s" : ""}`)
    this.renderFileList(files)
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
    this.hideFileList()
  }

  markNeutral() {
    this.swapState({ add: this.neutralClasses, remove: [...this.validClasses, ...this.invalidClasses] })
    this.element.dataset.dropzoneState = "neutral" // marqueur d'état inerte (cf. markValid)
    this.hideError()
    if (this.hasFilenameTarget) this.filenameTarget.textContent = this.defaultLabel
    this.setCount("")
    this.hideFileList()
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
    remove.forEach(c => this.boxTarget.classList.remove(c))
    add.forEach(c => this.boxTarget.classList.add(c))
  }

  hideError() {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }

  // Liste détaillée des fichiers (nom, poids, bouton de suppression) ---------
  // Rendue en dehors de `box` : les clics sur "supprimer" ne doivent pas
  // rouvrir le sélecteur de fichiers (pas de bubbling vers box#open).

  renderFileList(files) {
    if (!this.hasFileListTarget) return

    this.fileListTarget.innerHTML =  `<p class="text-sm font-semibold text-slate-700 mb-2">Fichiers sélectionnés</p>`
    
    this.revokeObjectUrls()
    this.fileListTarget.innerHTML += files.map((file, i) => `
      <li class="flex items-center gap-3 p-3 bg-white border border-slate-200 rounded-xl shadow-sm" data-index="${i}">
        <div class="w-9 h-9 rounded-lg bg-slate-100 flex items-center justify-center shrink-0">
          <svg class="w-4 h-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
          </svg>
        </div>
        <div class="flex-1 min-w-0">
          <a href="${this.urlLocale(file)}" target="_blank" rel="noopener"
             class="text-sm font-semibold truncate link link-primary block">${this.escapeHtml(file.name)}</a>
          <p class="text-xs text-slate-400">${(file.size / 1024).toFixed(1)} KB</p>
        </div>
        <button type="button" data-action="dropzone#removeFile" data-index="${i}"
                class="text-slate-400 hover:text-error shrink-0 p-1" aria-label="Retirer ce fichier">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
          </svg>
        </button>
      </li>
    `).join("")
    this.fileListTarget.classList.remove("hidden")
    this.fileListTarget.classList.add("flex")
  }

  hideFileList() {
    if (!this.hasFileListTarget) return
    this.revokeObjectUrls()
    this.fileListTarget.innerHTML = ""
    this.fileListTarget.classList.add("hidden")
    this.fileListTarget.classList.remove("flex")
  }

  // Le navigateur affiche ce qu'il sait rendre (images, PDF) ; il télécharge le
  // reste, y compris le HEIC des iPhone.
  urlLocale(file) {
    const url = URL.createObjectURL(file)
    this.objectUrls.push(url)
    return url
  }

  revokeObjectUrls() {
    this.objectUrls.forEach(url => URL.revokeObjectURL(url))
    this.objectUrls = []
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
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