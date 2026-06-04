class HomeController < ApplicationController
  def index
    @carousel_events = Evento.includes(:zonas).where(estado: "activo")
                         .order(created_at: :desc).limit(10).to_a
                         .reject(&:agotado?).first(5)
    @events = Evento.includes(:zonas).where(estado: "activo").order(fecha: :asc)
    if params[:buscar].present?
        @events = @events.search_by_name(params[:buscar])
    end
  end

  def pagina_eventos
    @evento = Evento.includes(:zonas).find_by(id: params[:id])

    if @evento.nil?
      redirect_to root_path, alert: "Evento no encontrado"
    else
      @zona = @evento.zonas.first  
      render "eventos/show", layout: "application"
    end
  end

  def miPerfil
    render "layouts/perfil"
  end

  def politica_privacidad
    # Vista estática de política de privacidad / Habeas Data (Ley 1581 de 2012)
  end
end