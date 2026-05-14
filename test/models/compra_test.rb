require "test_helper"

class CompraTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "compra@test.com", password: "password123", name: "Comprador")
    @evento = Evento.create!(
      nombre: "Concierto Test",
      descripcion: "Gran concierto",
      fecha: Date.tomorrow,
      hora: Time.now,
      imagen: "img.jpg",
      estado: "activo"
    )
    @zona = @evento.zonas.create!(nombre: "VIP", capacidad: 10, precio_cents: 10000)
  end

  test "debería crear una compra válida para usuario registrado" do
    compra = @user.compras.new(
      cantidad: 2,
      numero_orden: "ORD-TEST-001",
      precio_total: 20000,
      estado: "pendiente"
    )
    assert compra.valid?, "La compra debería ser válida: #{compra.errors.full_messages}"
    assert compra.save
  end

  test "no debería crear compra sin número de orden" do
    compra = @user.compras.new(cantidad: 1, precio_total: 10000)
    assert_not compra.save, "Guardó la compra sin número de orden"
    assert_includes compra.errors[:numero_orden], "no puede estar en blanco"
  end

  test "no debería permitir números de orden duplicados" do
    @user.compras.create!(cantidad: 1, numero_orden: "ORD-DUPL", precio_total: 10000, estado: "pendiente")
    compra2 = @user.compras.new(cantidad: 1, numero_orden: "ORD-DUPL", precio_total: 10000)
    assert_not compra2.valid?, "Permitió duplicar el número de orden"
    assert_includes compra2.errors[:numero_orden], "ya está en uso"
  end

  test "no debería permitir compras con cantidad cero" do
    compra = @user.compras.new(cantidad: 0, numero_orden: "ORD-CERO", precio_total: 10000)
    assert_not compra.save, "Permitió una compra con cantidad cero"
  end

  test "no debería permitir compras con cantidad negativa" do
    compra = @user.compras.new(cantidad: -1, numero_orden: "ORD-NEG", precio_total: 10000)
    assert_not compra.save, "Permitió una compra con cantidad negativa"
  end

  test "no debería crear compra sin precio_total" do
    compra = @user.compras.new(cantidad: 1, numero_orden: "ORD-SINPRECIO")
    assert_not compra.valid?
    assert compra.errors[:precio_total].present?
  end

  # ── Compras de invitado (RF-06) ───────────────────────────────────────────

  test "debería permitir compra de invitado con email válido (RF-06)" do
    compra = Compra.new(
      email: "invitado@test.com",
      cantidad: 1,
      numero_orden: "ORD-GUEST-01",
      precio_total: 10000,
      estado: "pendiente"
    )
    assert compra.valid?, "La compra de invitado debería ser válida: #{compra.errors.full_messages}"
    assert_nil compra.user_id
    assert compra.save
  end

  test "no debería permitir compra de invitado sin email" do
    compra = Compra.new(
      cantidad: 1,
      numero_orden: "ORD-GUEST-02",
      precio_total: 10000
    )
    assert_not compra.valid?
    assert compra.errors[:email].present?, "Debería requerir email para invitado"
  end

  test "no debería permitir compra de invitado con email inválido" do
    compra = Compra.new(
      email: "correo-invalido",
      cantidad: 1,
      numero_orden: "ORD-GUEST-BAD",
      precio_total: 10000
    )
    assert_not compra.valid?
    assert_includes compra.errors[:email], "no es válido"
  end

  test "debería tener muchos boletos" do
    compra = @user.compras.create!(cantidad: 2, numero_orden: "ORD-REL", precio_total: 20000, estado: "pendiente")
    2.times { compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pendiente") }
    assert_equal 2, compra.boletos.count
  end

  test "al destruir compra también se destruyen sus boletos" do
    compra = @user.compras.create!(cantidad: 1, numero_orden: "ORD-DEL", precio_total: 10000, estado: "pendiente")
    compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pendiente")
    assert_difference "Boleto.count", -1 do
      compra.destroy
    end
  end

  test "debería poder tener un pago asociado" do
    compra = @user.compras.create!(cantidad: 1, numero_orden: "ORD-PAGO", precio_total: 10000, estado: "pendiente")
    pago = compra.create_pago!(monto: 10000, estado: true, fecha_pago: Time.current, referencia: "REF-001")
    assert_equal pago, compra.reload.pago
  end

  test "debería tener estado pendiente por defecto" do
    compra = @user.compras.create!(cantidad: 1, numero_orden: "ORD-EST", precio_total: 10000)
    assert_equal "pendiente", compra.estado
  end

  test "debería poder actualizar estado a completado" do
    compra = @user.compras.create!(cantidad: 1, numero_orden: "ORD-COMP", precio_total: 10000, estado: "pendiente")
    compra.update!(estado: "completado")
    assert_equal "completado", compra.reload.estado
  end
end