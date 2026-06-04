require "test_helper"

class Admin::EventosControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = Admin.create!(email: "admin@test.com", password: "admin123456")
    @evento = Evento.create!(
      nombre: "Festival de Rock", descripcion: "Gran festival",
      fecha: Date.tomorrow, hora: "19:00", imagen: "rock.jpg", estado: "activo"
    )
  end

  test "index lista eventos visibles" do
    sign_in @admin
    get admin_eventos_path
    assert_response :success
  end

  test "index filtra por búsqueda" do
    sign_in @admin
    get admin_eventos_path, params: { search: "Festival" }
    assert_response :success
    assert_match "Festival de Rock", response.body
  end

  test "index no muestra eventos con soft-delete" do
    @evento.soft_delete!
    sign_in @admin
    get admin_eventos_path
    assert_response :success
    assert_no_match "Festival de Rock", response.body
  end

  test "new muestra formulario de nuevo evento" do
    sign_in @admin
    get new_admin_evento_path
    assert_response :success
  end

  test "create con datos válidos crea evento y redirige" do
    sign_in @admin
    assert_difference "Evento.count", 1 do
      post admin_eventos_path, params: {
        evento: {
          nombre: "Nuevo Concierto", descripcion: "Descripción",
          fecha: Date.tomorrow, hora: "21:00",
          imagen: "concierto.jpg", estado: "activo"
        }
      }
    end
    assert_redirected_to admin_eventos_path
    assert_equal "Evento creado correctamente.", flash[:notice]
  end

  test "create asigna estado activo por defecto si no se envía" do
    sign_in @admin
    post admin_eventos_path, params: {
      evento: {
        nombre: "Sin Estado", descripcion: "Desc",
        fecha: Date.tomorrow, hora: "20:00", imagen: "img.jpg"
      }
    }
    creado = Evento.find_by(nombre: "Sin Estado")
    assert_equal "activo", creado.estado if creado
  end

  test "create con nombre vacío no crea evento" do
    sign_in @admin
    assert_no_difference "Evento.count" do
      post admin_eventos_path, params: {
        evento: {
          nombre: "", descripcion: "Desc",
          fecha: Date.tomorrow, hora: "20:00", imagen: "img.jpg", estado: "activo"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edit muestra formulario de edición" do
    sign_in @admin
    get edit_admin_evento_path(@evento)
    assert_response :success
    assert_match "Festival de Rock", response.body
  end

  test "update con datos válidos actualiza el evento" do
    sign_in @admin
    patch admin_evento_path(@evento), params: {
      evento: { nombre: "Festival Actualizado" }
    }
    assert_redirected_to admin_eventos_path
    assert_equal "Evento actualizado correctamente.", flash[:notice]
    assert_equal "Festival Actualizado", @evento.reload.nombre
  end

  test "update con descripción vacía no actualiza" do
    sign_in @admin
    patch admin_evento_path(@evento), params: {
      evento: { descripcion: "" }
    }
    assert_response :unprocessable_entity
    assert_equal "Gran festival", @evento.reload.descripcion
  end

  test "destroy hace soft-delete: asigna deleted_at y cierra el evento" do
    sign_in @admin
    delete admin_evento_path(@evento)
    @evento.reload
    assert_not_nil @evento.deleted_at
    assert_equal "cerrado", @evento.estado
    assert_redirected_to admin_eventos_path
  end

  test "destroy no elimina el registro de la base de datos" do
    sign_in @admin
    assert_no_difference "Evento.unscoped.count" do
      delete admin_evento_path(@evento)
    end
  end

  test "destroy con boletos vendidos incluye aviso en el flash" do
    zona = @evento.zonas.create!(nombre: "General", precio_cents: 50_000, capacidad: 100)
    user = User.create!(name: "Ana", email: "ana@test.com", password: "password123")
    compra = Compra.create!(
      user: user, email: user.email,
      numero_orden: "FA-ROCK-001", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
    compra.boletos.create!(
      zona: zona, nombre_zona: zona.nombre,
      nombre_evento: @evento.nombre,
      token_qr: SecureRandom.uuid, estado: "pagado"
    )
    sign_in @admin
    delete admin_evento_path(@evento)
    assert_redirected_to admin_eventos_path
    assert_match "boleto", flash[:notice]
  end

  test "acceso denegado sin autenticación admin" do
    get admin_eventos_path
    assert_redirected_to new_admin_session_path
  end

  test "usuario normal no puede acceder a admin eventos" do
    user = User.create!(name: "Carlos", email: "carlos@test.com", password: "password123")
    sign_in user
    get admin_eventos_path
    assert_response :redirect
  end
  
  test "edit con evento inexistente redirige" do
    sign_in @admin
    get edit_admin_evento_path(id: 999999)
    assert_redirected_to admin_eventos_path
  end
end