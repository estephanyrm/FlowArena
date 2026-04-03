class Admin::UsuariosController < Admin::BaseController
  def index
    @usuarios = User.all
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
  end

  def edit
    @usuario = User.find(params[:id])
  end

  def update
    @usuario = User.find(params[:id])
    if @usuario.update(usuario_params)
      redirect_to admin_usuarios_path, notice: "Usuario actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @usuario = User.find(params[:id])
    @usuario.destroy
    redirect_to admin_usuarios_path, alert: "Usuario eliminado."
  end

  private

  def usuario_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
