require "test_helper"

class Admin::UsuariosControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = Admin.create!(email: "admin@test.com", password: "admin123456")
    @usuario = User.create!(name: "María López", email: "maria@test.com", password: "password123")
  end

  test "index lista todos los usuarios" do
    sign_in @admin
    get admin_usuarios_path
    assert_response :success
    assert_match "María López", response.body
  end

  test "index filtra usuarios por búsqueda de nombre" do
    User.create!(name: "Juan Pérez", email: "juan@test.com", password: "password123")
    sign_in @admin
    get admin_usuarios_path, params: { search: "María" }
    assert_response :success
    assert_match "María López", response.body
    assert_no_match "Juan Pérez", response.body
  end

  test "index filtra usuarios por búsqueda de email" do
    sign_in @admin
    get admin_usuarios_path, params: { search: "maria@test.com" }
    assert_response :success
    assert_match "maria@test.com", response.body
  end

  test "index sin parámetro de búsqueda devuelve todos los usuarios" do
    sign_in @admin
    get admin_usuarios_path
    assert_response :success
  end

  test "show muestra el detalle de un usuario" do
    sign_in @admin
    get admin_usuario_path(@usuario), as: :html
    assert_response :success
  end

  test "show muestra compras del usuario" do
    Compra.create!(
      user: @usuario, email: @usuario.email,
      numero_orden: "FA-USR-001", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
    sign_in @admin
    get admin_usuario_path(@usuario), as: :html
    assert_response :success
  end

  test "acceso denegado sin autenticación admin — index" do
    get admin_usuarios_path
    assert_redirected_to new_admin_session_path
  end

  test "acceso denegado sin autenticación admin — show" do
    get admin_usuario_path(@usuario)
    assert_redirected_to new_admin_session_path
  end

  test "usuario normal no puede acceder a admin usuarios" do
    sign_in @usuario
    get admin_usuarios_path
    assert_response :redirect
  end

  test "new muestra formulario de nuevo usuario" do
    sign_in @admin
    get new_admin_usuario_path
    assert_response :success
  end

  test "create con datos inválidos renderiza new" do
    sign_in @admin
    post admin_usuarios_path, params: {
      user: { name: "", email: "", password: "" }
    }
    assert_response :unprocessable_entity
  end
end