import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "error"]

  connect() {
    this.element.closest("form")
      ?.addEventListener("submit", this.validate.bind(this))
  }

  validate(event) {
    const checkbox = this.element.querySelector("input[name='habeas_data']")
    const error    = this.element.querySelector("#habeas-error")
    if (checkbox && !checkbox.checked) {
      event.preventDefault()
      error?.classList.remove("hidden")
      checkbox.closest("div").classList.add("ring-2", "ring-red-400", "rounded")
    }
  }
}