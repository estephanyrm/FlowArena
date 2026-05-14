require "test_helper"

class PagoTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "pago@test.com", password: "password123", name: "Pagador")
    @compra = @user.compras.create!(
      cantidad: 1,
      numero_orden: "ORD-PAGO-1",
      precio_total: 10000,
      estado: "pendiente"
    )
  end

  test "debería guardar un pago válido con todos sus campos" do
    pago = @compra.build_pago(
      monto: 10000,
      estado: true,
      fecha_pago: Time.current,
      referencia: "REF-VALIDO"
    )
    assert pago.valid?, "El pago debería ser válido: #{pago.errors.full_messages}"
    assert pago.save
  end

  test "no debería guardar un pago sin referencia" do
    pago = @compra.build_pago(monto: 10000, estado: true, fecha_pago: Time.current)
    assert_not pago.save, "Guardó el pago sin referencia"
  end

  test "no debería guardar un pago sin compra asociada" do
    pago = Pago.new(monto: 10000, estado: true, fecha_pago: Time.current, referencia: "REF-ORPHAN")
    assert_not pago.save, "Guardó un pago sin compra"
    assert_includes pago.errors[:compra], "debe existir"
  end

  test "debería marcar el pago como exitoso cuando estado es true" do
    pago = @compra.create_pago!(monto: 10000, estado: true, fecha_pago: Time.current, referencia: "REF-OK")
    assert pago.estado, "El pago debería estar en estado exitoso"
  end

  test "debería guardar la fecha del pago correctamente" do
    ahora = Time.current
    pago = @compra.create_pago!(monto: 10000, estado: true, fecha_pago: ahora, referencia: "REF-FECHA")
    assert_in_delta ahora.to_i, pago.fecha_pago.to_i, 2
  end

  test "debería pertenecer a la compra correcta" do
    pago = @compra.create_pago!(monto: 10000, estado: true, fecha_pago: Time.current, referencia: "REF-REL")
    assert_equal @compra, pago.compra
  end

  test "al destruir la compra también se destruye su pago" do
    @compra.create_pago!(monto: 10000, estado: true, fecha_pago: Time.current, referencia: "REF-DEL")
    assert_difference "Pago.count", -1 do
      @compra.destroy
    end
  end

  test "no debería permitir dos pagos para la misma compra" do
    @compra.create_pago!(monto: 10000, estado: true, fecha_pago: Time.current, referencia: "REF-1")
    assert_raises(ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid) do
      @compra.create_pago!(monto: 10000, estado: true, fecha_pago: Time.current, referencia: "REF-2")
    end
  end
end