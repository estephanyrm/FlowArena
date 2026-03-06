import { Controller } from "@hotwired/stimulus"
import { toggle } from "el-transition"

export default class extends Controller {

  static targets = ["dropdown", "mobileMenu"]

  toggleDropdown() {
    toggle(this.dropdownTarget)
  }

  toggleMobileMenu() {
    this.mobileMenuTarget.classList.toggle("hidden")
  }

}