// Controla comportamiento del sidebar
import { Controller } from "@hotwired/stimulus"
import { toggle, enter, leave } from "el-transition"

export default class extends Controller {
  static targets = ["hamburger", "closeIcon"]

  toggle() {
    const sidebar = document.getElementById("sidebar")
    const backdrop = document.getElementById("sidebarBackdrop")

    toggle(sidebar)
    toggle(backdrop)
    this.hamburgerTarget.classList.toggle("hidden")
    this.closeIconTarget.classList.toggle("hidden")
  }

  close() {
    const sidebar = document.getElementById("sidebar")
    const backdrop = document.getElementById("sidebarBackdrop")

    leave(sidebar)
    leave(backdrop)
    this.hamburgerTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
  }
}