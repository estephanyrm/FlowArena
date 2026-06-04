# ============================================
# Controlador: ValidacionController
# Descripción: Valida boletos escaneados por QR en el recinto.
# ============================================
class ValidacionController < ApplicationController
  # No requiere autenticación — es usado por personal con el escáner

  def show
    @boleto = Boleto.find_by(token_qr: params[:token])

    if @boleto.nil?
      @estado = :invalido
      @mensaje = "Este boleto no existe en el sistema."
      return
    end

    if @boleto.estado != "pagado"
      @estado = :invalido
      @mensaje = "Este boleto no está confirmado como pagado."
      return
    end

    if @boleto.usado?
      @estado = :ya_usado
      @mensaje = "Este boleto ya fue utilizado para ingresar."
      return
    end

    @estado = :valido
    @mensaje = "Boleto válido. Listo para ingresar."
  end

  def confirmar
    @boleto = Boleto.find_by(token_qr: params[:token])

    if @boleto.nil? || @boleto.estado != "pagado" || @boleto.usado?
      return redirect_to validar_boleto_path(params[:token]),
             alert: "No se puede marcar este boleto como usado."
    end

    @boleto.update!(usado: true)
    redirect_to validar_boleto_path(params[:token]),
                notice: "✅ Ingreso registrado correctamente."
  end
end