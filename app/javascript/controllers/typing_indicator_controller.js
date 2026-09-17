import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="typing-indicator"
export default class extends Controller {
  static targets = ["dot"]

  connect() {
    this.animate = this.animate.bind(this)
    this.frame = requestAnimationFrame(this.animate)
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
  }

  animate(time) {
    this.dotTargets.forEach((dot, index) => {
      const offset = Math.sin(time / 150 - index * 0.8) * 4
      dot.style.transform = `translateY(${offset}px)`
    })
    this.frame = requestAnimationFrame(this.animate)
  }
}
