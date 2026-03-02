import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loginButton"]
  connect() {
    this.loginButtonTarget.addEventListener("click", (e) => {
      console.log("Login button clicked")
    })   
  }
}