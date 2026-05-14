class Admin::DashboardController < Admin::BaseController
  def index
    @eventos  = Evento.all
    @usuarios = User.all

    compras_completadas = Compra.where(estado: "completado")

    @total_ingresos = compras_completadas.sum(:precio_total).to_f
    @total_boletos = Compra.where(estado: "completado")
                       .joins(:boletos)
                       .count("boletos.id")
    @total_eventos_activos  = Evento.where(estado: "activo").count
    @total_usuarios         = User.count
  end
end
