class ComprasController < ApplicationController
  before_action :set_evento, only: [ :new, :create ]

  def new
    @zonas = @evento.zonas.map do |zona|
      {
        id: zona.id,
        nombre: zona.nombre,
        precio: zona.precio_cents,
        capacidad: zona.capacidad,
        disponibles: zona.cupos_disponibles,
        color: color_para_zona(zona.nombre)
      }
    end
    @zonas_json = @zonas.to_json
  end

  def index
    if user_signed_in?
      @compras = current_user.compras
                             .includes(:boletos, :pago, zonas: :evento)
                             .order(created_at: :desc)
    else
      redirect_to new_user_session_path, alert: "Debes iniciar sesión para ver tus compras."
    end
  end

  def show
    @compra = Compra.includes(:boletos, :pago, zonas: :evento).find(params[:id])
    unless puede_ver_compra?(@compra)
      redirect_to root_path, alert: "No tienes acceso a esta compra."
    end
  end

  def create
    zona = @evento.zonas.find(params[:zona_id])
    cantidad = params[:cantidad].to_i

    # RF-03: Validar cupos antes de procesar
    if zona.cupos_disponibles < cantidad
      return redirect_to new_compra_path(evento_id: @evento.id),
             alert: "Lo sentimos, los cupos para esta zona se agotaron. Selecciona otra zona o cantidad."
    end

    # RF-06: usuario registrado o invitado con email
    email_comprador = user_signed_in? ? current_user.email : params[:email_invitado]

    @compra = Compra.new(
      user: current_user,
      email: email_comprador,
      numero_orden: generar_numero_orden,
      cantidad: cantidad,
      precio_total: zona.precio_cents * cantidad,
      estado: "pendiente"
    )

    if @compra.save
      session[:ultimo_email_compra] = email_comprador unless user_signed_in?
      cantidad.times do
        @compra.boletos.create!(
          zona: zona,
          token_qr: SecureRandom.uuid,
          estado: "pendiente"
        )
      end
      redirect_to pago_compra_path(@compra), notice: "Selección registrada. Confirma tu pago."
    else
      redirect_to new_compra_path(evento_id: @evento.id),
                  alert: "Error al procesar la compra. Intenta de nuevo."
    end
  end

  # GET /compras/:id/pago — RF-12: formulario de pago simulado
  def pago
    @compra = Compra.includes(boletos: :zona).find(params[:id])
    unless puede_ver_compra?(@compra)
      redirect_to root_path, alert: "No tienes acceso a esta compra."
    end
  end

  # POST /compras/:id/confirmar_pago — RF-12: confirmar y emitir boleto
  def confirmar_pago
    @compra = Compra.includes(boletos: :zona).find(params[:id])
    unless puede_ver_compra?(@compra)
      return redirect_to root_path, alert: "No tienes acceso a esta compra."
    end

    # Validar que se haya enviado un método de pago
    metodo = params[:metodo_pago].presence
    unless metodo
      return redirect_to pago_compra_path(@compra), alert: "Selecciona un método de pago."
    end

    # Validar campos según el método elegido
    error = validar_campos_pago(metodo)
    if error
      return redirect_to pago_compra_path(@compra), alert: error
    end

    ActiveRecord::Base.transaction do
      # Crear el registro de Pago (antes no se creaba — por eso el panel admin no mostraba nada)
      @compra.create_pago!(
        monto: @compra.precio_total,
        fecha_pago: Time.current,
        estado: true,
        referencia: "SIM-#{SecureRandom.hex(6).upcase}"
      )

      # Actualizar estado de la compra y sus boletos a "completado"
      @compra.update!(estado: "completado")
      @compra.boletos.update_all(estado: "pagado")
    end

    session[:ultimo_email_compra] = @compra.email
    redirect_to @compra, notice: "¡Pago exitoso! Tu boleto ha sido emitido."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to pago_compra_path(@compra), alert: "Error al procesar el pago: #{e.message}"
  end

  private

  def set_evento
    evento_id = params[:evento_id]
    @evento = Evento.includes(:zonas).find(evento_id)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Evento no encontrado."
  end

  def puede_ver_compra?(compra)
    return true if user_signed_in? && compra.user_id == current_user.id
    return true if compra.email == session[:ultimo_email_compra]
    false
  end

  def generar_numero_orden
    "FA-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def color_para_zona(nombre)
    {
      "Diamante"     => "#7C3AED",
      "VIP"          => "#2563EB",
      "Preferencial" => "#059669",
      "General"      => "#D97706"
    }[nombre] || "#6B7280"
  end

  # Valida que los campos requeridos según el método lleguen al servidor
  # (defensa en backend, complementa la validación del frontend)
  def validar_campos_pago(metodo)
    case metodo
    when "tarjeta"
      return "El número de tarjeta es requerido." if params[:numero_tarjeta].blank?
      return "La fecha de vencimiento es requerida." if params[:vencimiento].blank?
      return "El CVV es requerido." if params[:cvv].blank?
      return "El nombre en la tarjeta es requerido." if params[:nombre_tarjeta].blank?
    when "pse"
      return "Selecciona tu banco." if params[:banco_pse].blank?
    when "nequi"
      return "El número Nequi es requerido." if params[:numero_nequi].blank?
    when "efecty"
      # Efecty no requiere campos adicionales
    else
      return "Método de pago no válido."
    end
    nil # sin error
  end
end
