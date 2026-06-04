require "test_helper"

class ComprasFlujoTest < ActionDispatch::IntegrationTest
  def setup
    @evento = Evento.create!(
      nombre: "Festival Integración",
      descripcion: "Desc",
      fecha: Date.tomorrow,
      hora: Time.now,
      imagen: "img.jpg",
      estado: "activo"
    )
    @zona = @evento.zonas.create!(
      nombre: "General",
      capacidad: 10,
      precio_cents: 5000
    )
    @user = User.create!(
      email: "integra@test.com",
      password: "password123",
      name: "Integrador"
    )
  end

  # Formulario de selección

  test "GET new muestra el formulario con las zonas del evento" do
    sign_in @user
    get new_compra_path(evento_id: @evento.id)

    assert_response :success
    assert_match @zona.nombre, response.body
  end

  test "GET new funciona sin autenticación para invitados" do
    get new_compra_path(evento_id: @evento.id)
    assert_response :success
  end

  test "GET new redirige a root si el evento no existe" do
    sign_in @user
    get new_compra_path(evento_id: 99999)
    assert_redirected_to root_path
  end

  # Crear compra

  test "POST create genera una compra y redirige al pago para usuario registrado" do
    sign_in @user

    assert_difference "Compra.count", 1 do
      post compras_path, params: {
        evento_id: @evento.id,
        zona_id: @zona.id,
        cantidad: 2
      }
    end

    compra = Compra.last
    assert_equal 2, compra.cantidad
    assert_equal "pendiente", compra.estado
    assert_equal @user.id, compra.user_id
    assert_redirected_to pago_compra_path(compra)
  end

  test "POST create genera una compra para invitado con email" do
    assert_difference "Compra.count", 1 do
      post compras_path, params: {
        evento_id: @evento.id,
        zona_id: @zona.id,
        cantidad: 1,
        email_invitado: "invitado@test.com"
      }
    end

    compra = Compra.last
    assert_nil compra.user_id
    assert_equal "invitado@test.com", compra.email
  end

  test "POST create crea los boletos correspondientes a la cantidad" do
    sign_in @user

    post compras_path, params: {
      evento_id: @evento.id,
      zona_id: @zona.id,
      cantidad: 3
    }

    assert_equal 3, Compra.last.boletos.count
  end

  test "POST create redirige con alerta si no hay cupos suficientes" do
    # Llenamos la zona completamente
    compra_aux = @user.compras.create!(
      cantidad: 10, numero_orden: "ORD-AUX",
      precio_total: 50000, estado: "pendiente"
    )
    10.times { compra_aux.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pendiente") }

    sign_in @user
    post compras_path, params: {
      evento_id: @evento.id,
      zona_id: @zona.id,
      cantidad: 1
    }

    assert_redirected_to new_compra_path(evento_id: @evento.id)
  end

  # Formulario de pago

  test "GET pago muestra el formulario al dueño de la compra" do
    sign_in @user
    post compras_path, params: {
      evento_id: @evento.id,
      zona_id: @zona.id,
      cantidad: 1
    }
    compra = Compra.last

    get pago_compra_path(compra)
    assert_response :success
  end

    test "GET pago redirige a root si otro usuario intenta acceder" do
    compra = @user.compras.create!(
      cantidad: 1,
      numero_orden: "ORD-AJENO",
      precio_total: 5000,
      estado: "pendiente",
      email: @user.email
    )

    otro = User.create!(
      email: "otro@test.com",
      password: "password123",
      name: "Otro"
    )

    sign_in otro
    get pago_compra_path(compra)
    assert_redirected_to root_path
  end

  # Confirmar pago 

  test "POST confirmar_pago completa la compra y emite boletos" do
    sign_in @user
    post compras_path, params: {
      evento_id: @evento.id,
      zona_id: @zona.id,
      cantidad: 2
    }
    compra = Compra.last

    post confirmar_pago_compra_path(compra), params: {
      metodo_pago: "efecty"
    }

    compra.reload
    assert_equal "completado", compra.estado
    assert_not_nil compra.pago
    assert compra.boletos.all? { |b| b.estado == "pagado" }
    assert_redirected_to compra_path(compra)
  end

  test "POST confirmar_pago sin método de pago redirige con alerta" do
    sign_in @user
    post compras_path, params: {
      evento_id: @evento.id,
      zona_id: @zona.id,
      cantidad: 1
    }
    compra = Compra.last

    post confirmar_pago_compra_path(compra), params: {}

    assert_redirected_to pago_compra_path(compra)
    assert_equal "pendiente", compra.reload.estado
  end

  test "POST confirmar_pago con tarjeta sin datos redirige con alerta" do
    sign_in @user
    post compras_path, params: {
      evento_id: @evento.id,
      zona_id: @zona.id,
      cantidad: 1
    }
    compra = Compra.last

    post confirmar_pago_compra_path(compra), params: {
      metodo_pago: "tarjeta"
      # faltan numero_tarjeta, vencimiento, cvv, nombre_tarjeta
    }

    assert_redirected_to pago_compra_path(compra)
    assert_equal "pendiente", compra.reload.estado
  end

  require "test_helper"

# ============================================
# Pruebas de integración — ComprasController (casos faltantes)
# Cubre lo no contemplado en compras_flujo_test.rb:
#   • #show y #index (historial — HU-12)
#   • #cancelar
#   • Acceso de invitado mediante sesión (RF-06)
#   • Métodos de pago: PSE, Nequi, tarjeta completa, inválido
# ============================================
class ComprasAdicionalesFlujoTest < ActionDispatch::IntegrationTest
  def setup
    @evento = Evento.create!(
      nombre: "Festival Adicional",
      descripcion: "Desc",
      fecha: Date.tomorrow,
      hora: Time.now,
      imagen: "img.jpg",
      estado: "activo"
    )
    @zona = @evento.zonas.create!(nombre: "General", capacidad: 20, precio_cents: 6000)

    @user = User.create!(
      email: "compras_adic@test.com",
      password: "password123",
      name: "Adicional"
    )
  end

  # Helper: crea una compra con boleto para @user y la retorna
  def crear_compra_pendiente(numero_orden: "ORD-ADIC-001")
    compra = @user.compras.create!(
      cantidad: 1,
      numero_orden: numero_orden,
      precio_total: 6000,
      estado: "pendiente",
      email: @user.email
    )
    compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pendiente")
    compra
  end

  # ── #index — Historial de compras (HU-12) ─────────────────────────────────

  test "usuario autenticado puede ver su historial de compras" do
    compra = crear_compra_pendiente
    sign_in @user
    get mis_compras_path
    assert_response :success
    assert_match compra.numero_orden, response.body
  end

  test "usuario no autenticado es redirigido al intentar ver historial" do
    get mis_compras_path
    assert_redirected_to new_user_session_path
  end

  test "historial solo muestra las compras del usuario actual" do
    otro = User.create!(email: "otro_compras@test.com", password: "password123", name: "Otro")
    compra_otro = otro.compras.create!(
      cantidad: 1, numero_orden: "ORD-OTRO-001",
      precio_total: 6000, estado: "completado", email: otro.email
    )
    sign_in @user
    get mis_compras_path
    assert_no_match compra_otro.numero_orden, response.body
  end

  # ── #show — Detalle de compra ──

  test "dueño puede ver el detalle de su compra" do
    compra = crear_compra_pendiente(numero_orden: "ORD-SHOW-01")
    sign_in @user
    get compra_path(compra)
    assert_response :success
  end

  test "otro usuario no puede ver la compra ajena" do
    compra = crear_compra_pendiente(numero_orden: "ORD-SHOW-02")
    otro = User.create!(email: "ajeno_show@test.com", password: "password123", name: "Ajeno")
    sign_in otro
    get compra_path(compra)
    assert_redirected_to root_path
  end

  test "usuario no autenticado sin sesión de invitado no puede ver la compra" do
    compra = crear_compra_pendiente(numero_orden: "ORD-SHOW-03")
    # Sin sign_in y sin session[:ultimo_email_compra]
    get compra_path(compra)
    assert_redirected_to root_path
  end

  # ── #cancelar ─────────────────

  test "usuario puede cancelar su compra pendiente" do
    compra = crear_compra_pendiente(numero_orden: "ORD-CAN-01")
    sign_in @user
    patch cancelar_compra_path(compra)
    assert_redirected_to mis_compras_path
    assert_equal "cancelado", compra.reload.estado
    assert compra.boletos.reload.all? { |b| b.estado == "cancelado" }
  end

  test "usuario no puede cancelar una compra ya completada" do
    compra = crear_compra_pendiente(numero_orden: "ORD-CAN-02")
    compra.update!(estado: "completado")
    sign_in @user
    patch cancelar_compra_path(compra)
    assert_redirected_to mis_compras_path
    assert_equal "completado", compra.reload.estado
  end

  test "otro usuario no puede cancelar una compra ajena" do
    compra = crear_compra_pendiente(numero_orden: "ORD-CAN-03")
    otro = User.create!(email: "ajeno_cancel@test.com", password: "password123", name: "AjenoCan")
    sign_in otro
    patch cancelar_compra_path(compra)
    assert_redirected_to root_path
    assert_equal "pendiente", compra.reload.estado
  end

  # ── Métodos de pago (RF-12) ────

  test "POST confirmar_pago con PSE sin banco redirige con alerta" do
    compra = crear_compra_pendiente(numero_orden: "ORD-PSE-01")
    sign_in @user
    post confirmar_pago_compra_path(compra), params: { metodo_pago: "pse" }
    assert_redirected_to pago_compra_path(compra)
    assert_equal "pendiente", compra.reload.estado
  end

  test "POST confirmar_pago con Nequi sin número redirige con alerta" do
    compra = crear_compra_pendiente(numero_orden: "ORD-NEQ-01")
    sign_in @user
    post confirmar_pago_compra_path(compra), params: { metodo_pago: "nequi" }
    assert_redirected_to pago_compra_path(compra)
    assert_equal "pendiente", compra.reload.estado
  end

  test "POST confirmar_pago con método de pago inválido redirige con alerta" do
    compra = crear_compra_pendiente(numero_orden: "ORD-INV-01")
    sign_in @user
    post confirmar_pago_compra_path(compra), params: { metodo_pago: "bitcoin" }
    assert_redirected_to pago_compra_path(compra)
    assert_equal "pendiente", compra.reload.estado
  end

  test "POST confirmar_pago con tarjeta completa completa la compra" do
    compra = crear_compra_pendiente(numero_orden: "ORD-TAR-01")
    sign_in @user
    post confirmar_pago_compra_path(compra), params: {
      metodo_pago: "tarjeta",
      numero_tarjeta: "4111111111111111",
      vencimiento: "12/28",
      cvv: "123",
      nombre_tarjeta: "Juan Perez"
    }
    compra.reload
    assert_equal "completado", compra.estado
    assert_not_nil compra.pago
    assert compra.boletos.reload.all? { |b| b.estado == "pagado" }
    assert_redirected_to compra_path(compra)
  end

  test "POST confirmar_pago con Efecty completa la compra sin campos adicionales" do
    compra = crear_compra_pendiente(numero_orden: "ORD-EFE-01")
    sign_in @user
    post confirmar_pago_compra_path(compra), params: { metodo_pago: "efecty" }
    compra.reload
    assert_equal "completado", compra.estado
    assert_not_nil compra.pago
    assert_redirected_to compra_path(compra)
  end
end
end