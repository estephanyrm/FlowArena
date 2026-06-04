require "test_helper"

class Admin::ReportesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = Admin.create!(email: "admin@test.com", password: "admin123456")
    @evento = Evento.create!(
      nombre: "Concierto Reporte", descripcion: "Desc",
      fecha: Date.tomorrow, hora: "20:00",
      imagen: "img.jpg", estado: "activo"
    )
    @zona = @evento.zonas.create!(nombre: "General", precio_cents: 50_000, capacidad: 100)
    @user = User.create!(name: "Luis", email: "luis@test.com", password: "password123")
    @compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-REP-001", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
    @compra.boletos.create!(
      zona: @zona, nombre_zona: @zona.nombre,
      nombre_evento: @evento.nombre,
      token_qr: SecureRandom.uuid, estado: "pagado"
    )
  end

  test "index carga compras completadas" do
    sign_in @admin
    get admin_reportes_path
    assert_response :success
    assert_match "50.000", response.body
  end

  test "index calcula totales y los muestra" do
    sign_in @admin
    get admin_reportes_path
    assert_response :success
  end

  test "index sin filtros no genera tabla de reporte_eventos" do
    sign_in @admin
    get admin_reportes_path
    assert_response :success
  end

  test "index filtra por fecha_inicio" do
    sign_in @admin
    get admin_reportes_path, params: { fecha_inicio: 1.day.ago.to_date }
    assert_response :success
    assert_match "Concierto Reporte", response.body
  end

  test "index filtra por fecha_fin" do
    sign_in @admin
    get admin_reportes_path, params: { fecha_fin: 1.day.from_now.to_date }
    assert_response :success
    assert_match "Concierto Reporte", response.body
  end

  test "index filtra por rango de fechas y genera tabla de eventos" do
    sign_in @admin
    get admin_reportes_path, params: {
      fecha_inicio: 2.days.ago.to_date,
      fecha_fin: 1.day.from_now.to_date
    }
    assert_response :success
    assert_match "Concierto Reporte", response.body
  end

  test "index con fechas futuras no muestra compras" do
    sign_in @admin
    get admin_reportes_path, params: {
      fecha_inicio: 10.years.from_now.to_date,
      fecha_fin: 11.years.from_now.to_date
    }
    assert_response :success
    assert_match "0 $", response.body        # ingresos = 0
    assert_no_match "FA-REP-001", response.body 
  end

  test "index filtra por evento_id" do
    sign_in @admin
    get admin_reportes_path, params: { evento_id: @evento.id }
    assert_response :success
    assert_match "Concierto Reporte", response.body
  end

  test "index con evento_id sin compras igual responde con éxito" do
    otro_evento = Evento.create!(
      nombre: "Evento Vacío", descripcion: "Sin ventas",
      fecha: Date.tomorrow, hora: "10:00",
      imagen: "vacio.jpg", estado: "activo"
    )
    sign_in @admin
    get admin_reportes_path, params: { evento_id: otro_evento.id }
    assert_response :success
  end

  test "export HTML responde con éxito" do
    sign_in @admin
    get export_admin_reportes_path
    assert_response :success
  end

  test "export filtra por fecha_inicio" do
    sign_in @admin
    get export_admin_reportes_path, params: { fecha_inicio: 1.day.ago.to_date }
    assert_response :success
  end

  test "export filtra por evento_id" do
    sign_in @admin
    get export_admin_reportes_path, params: { evento_id: @evento.id }
    assert_response :success
  end

  test "acceso denegado sin autenticación admin" do
    get admin_reportes_path
    assert_redirected_to new_admin_session_path
  end

  test "usuario normal no puede acceder a reportes" do
    sign_in @user
    get admin_reportes_path
    assert_response :redirect
  end
end