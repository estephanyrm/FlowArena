class Admin::UsuariosController < Admin::BaseController
  def index
    @usuarios = User.all
    if params[:search].present?
      @usuarios = @usuarios.search_by_query(params[:search])
    end
  end

  def new
    @usuario = User.new
  end

  def create
    @usuario = User.new(usuario_params)
    if @usuario.save
      redirect_to admin_usuarios_path, notice: "Usuario creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @usuario = User.find(params[:id])
    @compras = @usuario.compras  # asegúrate de incluir esto
  end

  private

  def usuario_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end