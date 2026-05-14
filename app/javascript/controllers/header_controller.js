import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ["dropdown", "mobileMenu"]

  connect() {
    // Cerrar dropdown al hacer clic fuera
    this._clickOutside = (e) => {
      if (!this.element.contains(e.target)) {
        this._closeDropdown()
      }
    }
    document.addEventListener("click", this._clickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this._clickOutside)
  }

  toggleDropdown(e) {
    e.stopPropagation()
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.toggle("hidden")
    }
  }

  toggleMobileMenu(e) {
    e.stopPropagation()
    if (this.hasMobileMenuTarget) {
      this.mobileMenuTarget.classList.toggle("hidden")
    }
  }

  _closeDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.add("hidden")
    }
    if (this.hasMobileMenuTarget) {
      this.mobileMenuTarget.classList.add("hidden")
    }
  }
}