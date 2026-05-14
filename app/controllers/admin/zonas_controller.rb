# ============================================
# Controlador: Admin::ZonasController
# Descripción: Gestiona zonas de eventos.
# ============================================
class Admin::ZonasController < Admin::BaseController
  before_action :set_evento
  before_action :set_zona, only: [ :edit, :update, :destroy ]

  # Lista todas las zonas del evento
  def index
    @zonas = @evento.zonas
  end

  # Formulario para nueva zona
  def new
    @zona = @evento.zonas.build
  end

  # Formulario para editar zona existente
  def edit
  end

  # Crea una nueva zona para el evento
  def create
    @zona = @evento.zonas.build(zona_params)
    if @zona.save
      redirect_to admin_evento_zonas_path(@evento), notice: "Zona creada exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Elimina una zona del evento
  def destroy
    @zona.destroy
    redirect_to admin_evento_path(@evento), notice: "Zona eliminada correctamente"
  end

  # Actualiza una zona del evento
  def update
    if @zona.update(zona_params)
      redirect_to admin_evento_zonas_path(@evento), notice: "Zona actualizada correctamente"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_evento
    @evento = Evento.find(params[:evento_id])
  end

  def set_zona
    @zona = @evento.zonas.find(params[:id])
  end

 def zona_params
  p = params.require(:zona).permit(:nombre, :capacidad, :cupos_disponibles, :precio_cents)
  p[:precio_cents] = (p[:precio_cents].to_f).to_i if p[:precio_cents].present?
  p
end
end
