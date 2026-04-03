# ============================================
# Controlador: Admin::EventosController
# Descripción: Gestiona eventos en el panel administrativo.
# ============================================
class Admin::EventosController < Admin::BaseController
  before_action :set_evento, only: %i[ edit update destroy ]

  # Lista eventos con busqueda y ordenados por fecha
  def index
    @eventos = Evento.all
    @eventos = @eventos.where("nombre ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @eventos = @eventos.order(fecha: :asc)
  end

  # Formulario para nuevo evento
  def new
    @evento = Evento.new
  end

  # Crea un nuevo evento con validacion y manejo de errores
  def create
    @evento = Evento.new(evento_params)
    @evento.estado ||= 'activo'
    if @evento.save
      redirect_to admin_eventos_path, notice: 'Evento creado correctamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Formulario para editar evento existente
  def edit
  end

  # Actualiza un evento con validacion y manejo de errores
  def update
    if @evento.update(evento_params)
      redirect_to admin_eventos_path, notice: 'Evento actualizado correctamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Elimina un evento y redirige con mensaje de confirmacion
  def destroy
    @evento.destroy
    redirect_to admin_eventos_path, alert: 'Evento eliminado.'
  end

  private

  def set_evento
    @evento = Evento.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_eventos_path, alert: "Evento no encontrado."
  end

  def evento_params
    params.require(:evento).permit(:nombre, :descripcion, :fecha, :hora, :imagen, :estado)
  end

end