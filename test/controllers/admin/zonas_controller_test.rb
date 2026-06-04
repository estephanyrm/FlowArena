require "test_helper"

class Admin::ZonasControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = Admin.create!(email: "admin@test.com", password: "admin123456")
    @evento = Evento.create!(
      nombre: "Festival", descripcion: "Desc",
      fecha: Date.tomorrow, hora: "20:00",
      imagen: "img.jpg", estado: "activo"
    )
  end

  test "index lista zonas del evento" do
    @evento.zonas.create!(nombre: "General", precio_cents: 80_000, capacidad: 100)
    sign_in @admin
    get admin_evento_zonas_path(@evento)
    assert_response :success
    assert_match "General", response.body
  end

  test "new muestra formulario para nueva zona" do
    sign_in @admin
    get new_admin_evento_zona_path(@evento)
    assert_response :success
  end

  test "crear zona válida redirige con notice" do
    sign_in @admin
    assert_difference "Zona.count", 1 do
      post admin_evento_zonas_path(@evento), params: {
        zona: { nombre: "General", precio_cents: 80_000, capacidad: 100 }
      }
    end
    assert_redirected_to admin_evento_zonas_path(@evento)
    assert_equal "Zona creada exitosamente.", flash[:notice]
  end

  test "crear zona VIP con precio y capacidad válidos" do
    sign_in @admin
    assert_difference "Zona.count", 1 do
      post admin_evento_zonas_path(@evento), params: {
        zona: { nombre: "VIP", precio_cents: 500_000, capacidad: 500 }
      }
    end
    assert_redirected_to admin_evento_zonas_path(@evento)
  end

  test "crear zona con precio mayor a 3.000.000 no guarda y muestra error" do
    sign_in @admin
    assert_no_difference "Zona.count" do
      post admin_evento_zonas_path(@evento), params: {
        zona: { nombre: "Diamante", precio_cents: 3_500_000, capacidad: 50 }
      }
    end
    assert_response :unprocessable_entity
  end

  test "crear zona General con capacidad mayor a 4000 no guarda y muestra error" do
    sign_in @admin
    assert_no_difference "Zona.count" do
      post admin_evento_zonas_path(@evento), params: {
        zona: { nombre: "General", precio_cents: 50_000, capacidad: 5_000 }
      }
    end
    assert_response :unprocessable_entity
  end

  test "crear zona Diamante con capacidad mayor a 2000 no guarda y muestra error" do
    sign_in @admin
    assert_no_difference "Zona.count" do
      post admin_evento_zonas_path(@evento), params: {
        zona: { nombre: "Diamante", precio_cents: 200_000, capacidad: 2_001 }
      }
    end
    assert_response :unprocessable_entity
  end

  test "crear zona duplicada en el mismo evento no guarda y muestra error" do
    @evento.zonas.create!(nombre: "VIP", precio_cents: 300_000, capacidad: 200)
    sign_in @admin
    assert_no_difference "Zona.count" do
      post admin_evento_zonas_path(@evento), params: {
        zona: { nombre: "VIP", precio_cents: 200_000, capacidad: 100 }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edit muestra formulario de edición de zona" do
    zona = @evento.zonas.create!(nombre: "Preferencial", precio_cents: 150_000, capacidad: 500)
    sign_in @admin
    get edit_admin_evento_zona_path(@evento, zona)
    assert_response :success
    assert_match "Preferencial", response.body
  end

  test "update con datos válidos actualiza la zona" do
    zona = @evento.zonas.create!(nombre: "General", precio_cents: 80_000, capacidad: 100)
    sign_in @admin
    patch admin_evento_zona_path(@evento, zona), params: {
      zona: { precio_cents: 90_000 }
    }
    assert_redirected_to admin_evento_zonas_path(@evento)
    assert_equal 90_000, zona.reload.precio_cents
  end

  test "destroy elimina zona sin boletos vendidos" do
    zona = @evento.zonas.create!(nombre: "General", precio_cents: 50_000, capacidad: 100)
    sign_in @admin
    assert_difference "Zona.count", -1 do
      delete admin_evento_zona_path(@evento, zona)
    end
    assert_redirected_to admin_evento_zonas_path(@evento)
  end

  test "destroy no elimina zona con boletos vendidos" do
    zona = @evento.zonas.create!(nombre: "VIP", precio_cents: 200_000, capacidad: 100)
    user = User.create!(name: "Ana", email: "ana@test.com", password: "password123")
    compra = Compra.create!(
      user: user, email: user.email,
      numero_orden: "FA-ZONA-001", cantidad: 1,
      precio_total: 200_000, estado: "completado"
    )
    compra.boletos.create!(
      zona: zona, nombre_zona: zona.nombre,
      nombre_evento: @evento.nombre,
      token_qr: SecureRandom.uuid, estado: "pagado"
    )
    sign_in @admin
    assert_no_difference "Zona.count" do
      delete admin_evento_zona_path(@evento, zona)
    end
    assert_redirected_to admin_evento_zonas_path(@evento)
    assert_match "boletos vendidos", flash[:alert]
  end

  test "acceso denegado sin autenticación admin" do
    get new_admin_evento_zona_path(@evento)
    assert_redirected_to new_admin_session_path
  end

  test "usuario normal no puede acceder a admin zonas" do
    user = User.create!(name: "Pedro", email: "pedro@test.com", password: "password123")
    sign_in user
    get new_admin_evento_zona_path(@evento)
    assert_response :redirect
  end

  test "update con datos inválidos renderiza edit" do
    sign_in @admin
    @zona = @evento.zonas.create!(nombre: "General", precio_cents: 10_000, capacidad: 50)
    patch admin_evento_zona_path(@evento, @zona), params: {
      zona: { nombre: "", capacidad: -1 }
    }
    assert_response :unprocessable_entity
  end
end