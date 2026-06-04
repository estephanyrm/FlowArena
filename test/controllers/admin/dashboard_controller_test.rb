require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = Admin.create!(email: "admin@test.com", password: "admin123456")
  end

  test "admin autenticado puede ver el dashboard" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
  end

  test "dashboard carga eventos y usuarios" do
    Evento.create!(
      nombre: "Concierto Test", descripcion: "Desc", fecha: Date.tomorrow,
      hora: "20:00", imagen: "img.jpg", estado: "activo"
    )
    User.create!(name: "Ana", email: "ana@test.com", password: "password123")
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
  end

  test "dashboard calcula total_ingresos de compras completadas" do
    user = User.create!(name: "Luis", email: "luis@test.com", password: "password123")
    Compra.create!(
      user: user, email: user.email,
      numero_orden: "FA-001", cantidad: 2,
      precio_total: 100_000, estado: "completado"
    )
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
  end

  test "dashboard muestra total_eventos_activos y total_usuarios" do
    Evento.create!(
      nombre: "Festival", descripcion: "Desc", fecha: Date.tomorrow,
      hora: "18:00", imagen: "img.jpg", estado: "activo"
    )
    User.create!(name: "Bob", email: "bob@test.com", password: "password123")
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
  end

  test "usuario no autenticado es redirigido al login de admin" do
    get admin_dashboard_path
    assert_redirected_to new_admin_session_path
  end

  test "usuario normal no puede acceder al dashboard admin" do
    user = User.create!(name: "Carlos", email: "carlos@test.com", password: "password123")
    sign_in user
    get admin_dashboard_path
    assert_response :redirect
  end
end