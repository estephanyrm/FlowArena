# ============================================
# Controlador: Home
# Descripción: Maneja la página principal del sistema.
# ============================================

class HomeController < ApplicationController
  def index
    @carousel_events = Evento.order(created_at: :desc).limit(5)
    @events = Evento.where(estado: 'activo').order(fecha: :asc)
  end

  def pagina_eventos
    # Buscamos el evento por el ID que viene en el link
    @evento = Evento.find_by(id: params[:id])

    # Si el ID no existe, mandamos al usuario a la home
    if @evento.nil?
      redirect_to root_path, alert: "Evento no encontrado"
    else
      render 'layouts/eventos'
    end
  end

  def miPerfil
    render 'layouts/perfil'
  end
end