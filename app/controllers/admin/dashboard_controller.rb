class Admin::DashboardController < Admin::BaseController
  def index
    @eventos = Evento.all
    @usuarios = User.all
  end
end