require "test_helper"

class ComprasControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = User.create!(name: "Test User", email: "test@test.com", password: "password123")
    @evento = Evento.create!(
      nombre: "Concierto", descripcion: "Desc",
      fecha: Date.tomorrow, hora: "20:00",
      imagen: "img.jpg", estado: "activo"
    )
    @zona = @evento.zonas.create!(nombre: "General", precio_cents: 50_000, capacidad: 10)
  end

  test "index con usuario autenticado muestra sus compras" do
    Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-IDX-001", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
    sign_in @user
    get mis_compras_path
    assert_response :success
    assert_match "FA-IDX-001", response.body
  end

  test "index sin autenticación redirige al login" do
    get mis_compras_path
    assert_redirected_to new_user_session_path
    assert_match "iniciar sesión", flash[:alert]
  end

  test "usuario puede ver su propia compra" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-SHOW-001", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
    sign_in @user
    get compra_path(compra)
    assert_response :success
    assert_match "FA-SHOW-001", response.body
  end

  test "usuario NO puede ver la compra de otro usuario" do
    otro = User.create!(name: "Otro", email: "otro@test.com", password: "password123")
    compra_ajena = Compra.create!(
      user: otro, email: otro.email,
      numero_orden: "FA-OTRO-001", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
    sign_in @user
    get compra_path(compra_ajena)
    assert_redirected_to root_path
    assert_match "No tienes acceso", flash[:alert]
  end

  test "usuario autenticado crea compra válida" do
    sign_in @user
    assert_difference "Compra.count", 1 do
      post compras_path, params: {
        evento_id: @evento.id,
        zona_id: @zona.id,
        cantidad: 2
      }
    end
    assert_redirected_to pago_compra_path(Compra.last)
  end

  test "crear compra con más unidades que cupos disponibles redirige con alert" do
    compra_base = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-LLENO-001", cantidad: 10,
      precio_total: 500_000, estado: "completado"
    )
    10.times do
      compra_base.boletos.create!(
        zona: @zona, nombre_zona: @zona.nombre,
        nombre_evento: @evento.nombre,
        token_qr: SecureRandom.uuid, estado: "pagado"
      )
    end
    sign_in @user
    assert_no_difference "Compra.count" do
      post compras_path, params: {
        evento_id: @evento.id,
        zona_id: @zona.id,
        cantidad: 1
      }
    end
    assert_redirected_to new_compra_path(evento_id: @evento.id)
    assert_match "cupos", flash[:alert]
  end

  test "invitado puede crear compra con email" do
    assert_difference "Compra.count", 1 do
      post compras_path, params: {
        evento_id: @evento.id,
        zona_id: @zona.id,
        cantidad: 1,
        email_invitado: "invitado@correo.com"
      }
    end
    compra = Compra.last
    assert_nil compra.user_id
    assert_equal "invitado@correo.com", compra.email
  end

  test "usuario cancela su compra pendiente" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-CAN-001", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    sign_in @user
    patch cancelar_compra_path(compra)
    assert_equal "cancelado", compra.reload.estado
    assert_redirected_to mis_compras_path
    assert_match "cancelada", flash[:notice]
  end

  test "no se puede cancelar una compra ya completada" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-COMP-001", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
    sign_in @user
    patch cancelar_compra_path(compra)
    assert_equal "completado", compra.reload.estado
    assert_redirected_to mis_compras_path
    assert_match "pendientes", flash[:alert]
  end

  test "no se puede cancelar la compra de otro usuario" do
    otro = User.create!(name: "Otro", email: "otro@test.com", password: "password123")
    compra_ajena = Compra.create!(
      user: otro, email: otro.email,
      numero_orden: "FA-AJEN-001", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    sign_in @user
    patch cancelar_compra_path(compra_ajena)
    assert_equal "pendiente", compra_ajena.reload.estado
    assert_redirected_to root_path
  end

  test "dueño de compra puede ver la página de pago" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-PAGO-001", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    sign_in @user
    get pago_compra_path(compra)
    assert_response :success
  end

  test "tercero no puede ver la página de pago" do
    otro = User.create!(name: "Otro", email: "otro2@test.com", password: "password123")
    compra = Compra.create!(
      user: otro, email: otro.email,
      numero_orden: "FA-PAGO-002", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    sign_in @user
    get pago_compra_path(compra)
    assert_redirected_to root_path
    assert_match "No tienes acceso", flash[:alert]
  end

  test "confirmar_pago sin método de pago redirige con alert" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-CONF-001", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    sign_in @user
    post confirmar_pago_compra_path(compra), params: {}
    assert_redirected_to pago_compra_path(compra)
    assert_match "método de pago", flash[:alert]
  end

  test "confirmar_pago con tarjeta pero sin número redirige con alert" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-CONF-002", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    sign_in @user
    post confirmar_pago_compra_path(compra), params: { metodo_pago: "tarjeta" }
    assert_redirected_to pago_compra_path(compra)
    assert_match "tarjeta", flash[:alert]
  end

  test "confirmar_pago con tarjeta completa procesa el pago" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-CONF-003", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    compra.boletos.create!(
      zona: @zona, nombre_zona: @zona.nombre,
      nombre_evento: @evento.nombre,
      token_qr: SecureRandom.uuid, estado: "pendiente"
    )
    sign_in @user
    post confirmar_pago_compra_path(compra), params: {
      metodo_pago: "tarjeta",
      numero_tarjeta: "4111111111111111",
      vencimiento: "12/27",
      cvv: "123",
      nombre_tarjeta: "Test User"
    }
    assert_equal "completado", compra.reload.estado
    assert_redirected_to compra_path(compra)
    assert_match "exitoso", flash[:notice]
  end

  test "confirmar_pago con PSE pero sin banco redirige con alert" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-CONF-004", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    sign_in @user
    post confirmar_pago_compra_path(compra), params: { metodo_pago: "pse" }
    assert_redirected_to pago_compra_path(compra)
    assert_match "banco", flash[:alert]
  end

  test "confirmar_pago con nequi pero sin número redirige con alert" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-CONF-005", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    sign_in @user
    post confirmar_pago_compra_path(compra), params: { metodo_pago: "nequi" }
    assert_redirected_to pago_compra_path(compra)
    assert_match "Nequi", flash[:alert]
  end

  test "confirmar_pago con método desconocido redirige con alert" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-CONF-006", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    sign_in @user
    post confirmar_pago_compra_path(compra), params: { metodo_pago: "cripto" }
    assert_redirected_to pago_compra_path(compra)
    assert_match "no válido", flash[:alert]
  end

  test "confirmar_pago con efecty completa el pago" do
    compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-CONF-007", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    compra.boletos.create!(
      zona: @zona, nombre_zona: @zona.nombre,
      nombre_evento: @evento.nombre,
      token_qr: SecureRandom.uuid, estado: "pendiente"
    )
    sign_in @user
    post confirmar_pago_compra_path(compra), params: { metodo_pago: "efecty" }
    assert_equal "completado", compra.reload.estado
    assert_redirected_to compra_path(compra)
  end

  test "confirmar_pago por tercero redirige a root con alert" do
    otro = User.create!(name: "Otro", email: "otro3@test.com", password: "password123")
    compra = Compra.create!(
      user: otro, email: otro.email,
      numero_orden: "FA-CONF-008", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    sign_in @user
    post confirmar_pago_compra_path(compra), params: { metodo_pago: "efecty" }
    assert_redirected_to root_path
    assert_match "No tienes acceso", flash[:alert]
  end

  test "create redirige si no hay cupos disponibles" do
    # Zona con capacidad 1
    zona = @evento.zonas.create!(nombre: "VIP", precio_cents: 50_000, capacidad: 1)
    
    # Crear un boleto que ocupe el único cupo disponible
    compra_previa = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-PREV-001", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
    compra_previa.boletos.create!(
      zona: zona,
      nombre_zona: zona.nombre,
      nombre_evento: @evento.nombre,
      token_qr: SecureRandom.uuid,
      estado: "pagado"
    )

    # Ahora cupos_disponibles = 1 - 1 = 0
    sign_in @user
    post compras_path, params: { evento_id: @evento.id, zona_id: zona.id, cantidad: 1 }
    assert_redirected_to new_compra_path(evento_id: @evento.id)
    assert_match "cupos", flash[:alert]
  end

  test "confirmar_pago maneja error de RecordInvalid" do
    sign_in @user
    # Crear la compra dentro del test si no existe en setup
    @compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-ERR-001", cantidad: 1,
      precio_total: 10_000, estado: "pendiente"
    )
    @compra.create_pago!(monto: 1000, fecha_pago: Time.current, estado: true, referencia: "SIM-YA")
    post confirmar_pago_compra_path(@compra), params: { metodo_pago: "efecty" }
    assert_redirected_to pago_compra_path(@compra)
    assert_match "Error", flash[:alert]
  end
end