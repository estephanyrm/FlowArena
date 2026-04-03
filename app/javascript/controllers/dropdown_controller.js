// ============================================
// Controlador: Dropdown
// Descripción: Maneja menús desplegables
// ============================================
import { Controller } from "@hotwired/stimulus"
import { toggle } from "el-transition"

export default class extends Controller {
  static targets = ["menu", "arrow"]

  toggle() {
    toggle(this.menuTarget)
    this.arrowTarget.classList.toggle("rotate-180")
  }
}