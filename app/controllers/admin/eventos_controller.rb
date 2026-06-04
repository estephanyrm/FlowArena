# ============================================
# Controlador: Admin::EventosController
# Descripción: Gestiona eventos en el panel administrativo.
# ============================================
class Admin::EventosController < Admin::BaseController
  before_action :set_evento, only: %i[ edit update destroy ]

  # Lista solo eventos NO eliminados, con búsqueda y orden por fecha
  def index
    @eventos = Evento.visible
    @eventos = @eventos.where("nombre ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @eventos = @eventos.order(fecha: :asc)
  end

  def show
    @evento = Evento.includes(:zonas).find(params[:id])
 
    if @evento.eliminado?
      redirect_to root_path, alert: "Este evento ya no está disponible."
      return
    end
 
    @zona = @evento.zonas.first
    # Rails renderiza automáticamente app/views/eventos/show.html.erb
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Evento no encontrado."
  end

  def new
    @evento = Evento.new
  end

  def create
    @evento = Evento.new(evento_params)
    @evento.estado ||= "activo"
    if @evento.save
      redirect_to admin_eventos_path, notice: "Evento creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @evento.update(evento_params)
      redirect_to admin_eventos_path, notice: "Evento actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Soft delete: oculta el evento del sistema sin borrar ningún dato.
  # Los boletos ya vendidos permanecen intactos y siguen siendo visibles
  # para los clientes gracias al snapshot guardado en cada boleto.
  # En app/controllers/admin/eventos_controller.rb
  def destroy
    boletos_vendidos = Boleto.joins(:zona)
                            .where(zonas: { evento_id: @evento.id })
                            .where(estado: "pagado")
                            .count

    @evento.soft_delete!
    nombre = @evento.nombre

    if boletos_vendidos > 0
      redirect_to admin_eventos_path,
        notice: "Evento '#{nombre}' eliminado. Había #{boletos_vendidos} boleto(s) vendido(s) — los clientes podrán seguir viéndolos."
    else
      redirect_to admin_eventos_path,
        notice: "Evento '#{nombre}' eliminado correctamente."
    end
  rescue => e
    redirect_to admin_eventos_path,        # :nocov:
      alert: "No se pudo eliminar el evento: #{e.message}"  # :nocov:
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