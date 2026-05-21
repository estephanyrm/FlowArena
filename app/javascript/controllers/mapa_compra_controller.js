import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    zonas: Array,
    eventoId: Number
  }

  static targets = [
    "zonaId", "cantidad", "email"
  ]

  connect() {
    this.zonaSeleccionada = null
    this.cantidadActual = 1
    this.zonasMap = {}
    this.zonasValue.forEach(z => {
      this.zonasMap[z.id] = z
    })

    // Escuchar cambios en el checkbox de habeas data para re-evaluar el botón
    const habeasCheckbox = document.querySelector("input[name='habeas_data']")
    if (habeasCheckbox) {
      habeasCheckbox.addEventListener("change", () => this._actualizarBoton())
    }
  }

  // ── Selección de zona (desde SVG o tarjeta) ──
  seleccionarZona(event) {
    const zonaId = parseInt(event.currentTarget.dataset.zonaId)
    if (!zonaId) return

    const zona = this.zonasMap[zonaId]
    if (!zona) return

    // Validar que haya cupos disponibles (RF-03)
    if (zona.disponibles <= 0) {
      this._mostrarToast("⚠️ Esta zona está agotada. Selecciona otra.", "error")
      return
    }

    this.zonaSeleccionada = zona
    this.cantidadActual = 1

    this._actualizarSVG(zonaId)
    this._actualizarTarjetas(zonaId)
    this._mostrarPanelSeleccionado(zona)
    this._actualizarTotales()
    this._mostrarToast(`✓ Zona ${zona.nombre} seleccionada`)
  }

  // ── Controles de cantidad ──
  menos() {
    if (this.cantidadActual > 1) {
      this.cantidadActual--
      this._actualizarTotales()
    }
  }

  mas() {
    if (!this.zonaSeleccionada) return
    const maxCantidad = Math.min(10, this.zonaSeleccionada.disponibles)
    if (this.cantidadActual < maxCantidad) {
      this.cantidadActual++
      this._actualizarTotales()
    }
  }

  // ── Validación de email invitado (RF-06) ──
  validarEmail() {
    this._actualizarBoton()
  }

  // ── Privados ──

  _actualizarSVG(zonaId) {
    document.querySelectorAll(".zona-anillo").forEach(el => {
      const esSeleccionado = parseInt(el.dataset.zonaId) === zonaId
      el.style.opacity = esSeleccionado ? "1" : "0.35"
      el.style.filter = esSeleccionado
        ? "brightness(1.12) drop-shadow(0 0 8px rgba(0,0,0,0.2))"
        : "none"
    })
  }

  _actualizarTarjetas(zonaId) {
    document.querySelectorAll(".zona-card").forEach(el => {
      const esActivo = parseInt(el.dataset.zonaId) === zonaId
      el.style.borderColor = esActivo
        ? (this.zonasMap[zonaId]?.color || "#7C3AED")
        : "transparent"
      el.style.background = esActivo ? "#FAF5FF" : "white"
    })
  }

  _mostrarPanelSeleccionado(zona) {
    document.getElementById("panel-vacio")?.classList.add("hidden")
    const panelSel = document.getElementById("panel-seleccionado")
    panelSel?.classList.remove("hidden")

    // Badge de zona
    const badge = document.getElementById("zona-badge")
    if (badge) {
      badge.style.borderColor = zona.color + "40"
      badge.style.background = zona.color + "0D"
    }
    const dot = document.getElementById("zona-dot")
    if (dot) dot.style.background = zona.color

    document.getElementById("zona-nombre-panel").textContent = zona.nombre

    const disponibles = zona.disponibles
    document.getElementById("zona-disponibles-panel").textContent =
      `${disponibles.toLocaleString("es-CO")} cupos disponibles`

    const precioUnit = this._formatCOP(zona.precio )
    document.getElementById("zona-precio-panel").textContent = precioUnit
    document.getElementById("zona-precio-panel").style.color = zona.color

    // Barra de disponibilidad
    const vendidos = zona.capacidad - zona.disponibles
    const pctVendido = Math.round((vendidos / zona.capacidad) * 100)
    document.getElementById("barra-texto").textContent =
      `${disponibles.toLocaleString("es-CO")} de ${zona.capacidad.toLocaleString("es-CO")}`
    const barraFill = document.getElementById("barra-fill")
    if (barraFill) {
      barraFill.style.width = pctVendido + "%"
      barraFill.style.background = zona.color
    }

    // Actualizar campos ocultos del form
    const hiddenZonaId = document.getElementById("hidden-zona-id")
    if (hiddenZonaId) hiddenZonaId.value = zona.id

    this._actualizarBoton()
  }

  _actualizarTotales() {
    if (!this.zonaSeleccionada) return

    const precio = this.zonaSeleccionada.precio
    const subtotal = precio * this.cantidadActual
    const total = subtotal

    const plural = this.cantidadActual > 1 ? "boletos" : "boleto"
    document.getElementById("subtotal-label").textContent =
      `${this.cantidadActual} ${plural} × ${this._formatCOP(precio)}`
    document.getElementById("subtotal-valor").textContent = this._formatCOP(subtotal)
    document.getElementById("total-valor").textContent = this._formatCOP(total)

    // Cantidad display
    document.getElementById("cantidad-display").textContent = this.cantidadActual

    // Botones +/-
    const btnMenos = document.getElementById("btn-menos")
    const btnMas = document.getElementById("btn-mas")
    if (btnMenos) btnMenos.disabled = this.cantidadActual <= 1
    const maxCantidad = Math.min(10, this.zonaSeleccionada.disponibles)
    if (btnMas) btnMas.disabled = this.cantidadActual >= maxCantidad

    // Actualizar campo hidden cantidad
    const hiddenCantidad = document.getElementById("hidden-cantidad")
    if (hiddenCantidad) hiddenCantidad.value = this.cantidadActual

    this._actualizarBoton()
  }

  _actualizarBoton() {
    const btn = document.getElementById("btn-continuar")
    if (!btn || !this.zonaSeleccionada) return

    // Verificar email para invitados
    const emailInput = document.getElementById("email-invitado")
    let emailValido = true
    if (emailInput) {
      const emailVal = emailInput.value.trim()
      emailValido = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailVal)
      // Sincronizar campo hidden
      const hiddenEmail = document.getElementById("hidden-email")
      if (hiddenEmail) hiddenEmail.value = emailVal
    }

    // Verificar habeas data (checkbox obligatorio)
    const habeasCheckbox = document.querySelector("input[name='habeas_data']")
    const habeasAceptado = habeasCheckbox ? habeasCheckbox.checked : true

    const habilitado = this.zonaSeleccionada && emailValido && habeasAceptado

    btn.disabled = !habilitado
    if (habilitado) {
      btn.classList.remove("bg-purple-300", "cursor-not-allowed")
      btn.classList.add("cursor-pointer", "hover:-translate-y-0.5", "hover:shadow-lg")
      btn.style.background = this.zonaSeleccionada.color
      btn.style.boxShadow = `0 4px 20px ${this.zonaSeleccionada.color}50`
    } else {
      btn.classList.add("bg-purple-300", "cursor-not-allowed")
      btn.classList.remove("cursor-pointer", "hover:-translate-y-0.5", "hover:shadow-lg")
      btn.style.background = ""
      btn.style.boxShadow = ""
    }
  }

  _formatCOP(valor) {
    return new Intl.NumberFormat("es-CO", {
      style: "currency",
      currency: "COP",
      minimumFractionDigits: 0
    }).format(valor)
  }

  _mostrarToast(mensaje, tipo = "success") {
    // Eliminar toast anterior si existe
    document.getElementById("toast-mapa")?.remove()

    const toast = document.createElement("div")
    toast.id = "toast-mapa"
    toast.className = [
      "fixed bottom-6 left-1/2 -translate-x-1/2 z-50",
      "bg-white border shadow-lg rounded-xl px-4 py-3",
      "text-sm font-medium flex items-center gap-2",
      "transition-all duration-300 translate-y-20 opacity-0",
      tipo === "error" ? "border-red-200 text-red-700" : "border-purple-200 text-gray-800"
    ].join(" ")
    toast.textContent = mensaje

    document.body.appendChild(toast)
    requestAnimationFrame(() => {
      toast.classList.remove("translate-y-20", "opacity-0")
    })

    setTimeout(() => {
      toast.classList.add("translate-y-20", "opacity-0")
      setTimeout(() => toast.remove(), 300)
    }, 2500)
  }
}