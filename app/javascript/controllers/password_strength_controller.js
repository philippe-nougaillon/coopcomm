import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input",
    "ruleLength",
    "ruleUpper",
    "ruleLower",
    "ruleDigit",
    "ruleSymbol"
  ]

  connect() {
    this.check()
  }

  check() {
    const value = this.inputTarget.value

    this.toggleRule(this.ruleLengthTarget, value.length >= 12)
    this.toggleRule(this.ruleUpperTarget, /[A-Z]/.test(value))
    this.toggleRule(this.ruleLowerTarget, /[a-z]/.test(value))
    this.toggleRule(this.ruleDigitTarget, /[0-9]/.test(value))
    this.toggleRule(this.ruleSymbolTarget, /[^A-Za-z0-9]/.test(value))
  }

  toggleRule(element, isValid) {
    const icon = element.querySelector(".rule-icon")

    if (isValid) {
      element.classList.remove("text-slate-400")
      element.classList.add("text-slate-700", "font-medium")
      icon.textContent = "●"
    } else {
      element.classList.remove("text-slate-700", "font-medium")
      element.classList.add("text-slate-400")
      icon.textContent = "○"
    }
  }
}