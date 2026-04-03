# ============================================
# Controlador: Home
# Descripción: Maneja la página principal del sistema.
# ============================================

class HomeController < ApplicationController
  def index
    @carousel_events = Evento.order(created_at: :desc).limit(5)
    @events = Evento.where(estado: 'activo').order(fecha: :asc)
  end
  def miPerfil
    render 'layouts/perfil'
  end
end