# ============================================
# Controlador: Home
# Descripción: Maneja la página principal del sistema.
# ============================================

class HomeController < ApplicationController
  def index
    @carousel_events = Evento.includes(:zonas).where(estado: "activo").order(created_at: :desc).limit(5).select { |e| !e.agotado? }
    @events = Evento.includes(:zonas).where(estado: "activo").order(fecha: :asc)
    if params[:buscar].present?
        @events = @events.search_by_name(params[:buscar])
    end
  end

  def pagina_eventos
    # Buscamos el evento por el ID que viene en el link
    @evento = Evento.includes(:zonas).find_by(id: params[:id])
    @zona = @evento.zonas.first

    # Si el ID no existe, mandamos al usuario a la home
    if @evento.nil?
      redirect_to root_path, alert: "Evento no encontrado"
    else
      render "layouts/eventos"
    end
  end

  def miPerfil
    render "layouts/perfil"
  end

  def politica_privacidad
    # Vista estática de política de privacidad / Habeas Data (Ley 1581 de 2012)
  end
end