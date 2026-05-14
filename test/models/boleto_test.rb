require "test_helper"

class BoletoTest < ActiveSupport::TestCase
  def setup
    @evento = Evento.create!(
      nombre: "Festival Test",
      descripcion: "Desc",
      fecha: Date.tomorrow,
      hora: Time.now,
      imagen: "img.jpg",
      estado: "activo"
    )
    @zona = @evento.zonas.create!(nombre: "General", capacidad: 100, precio_cents: 5000)
    @user = User.create!(email: "boleto@test.com", password: "password123", name: "Comprador")
    @compra = @user.compras.create!(
      cantidad: 1,
      numero_orden: "ORD-BOLETO-1",
      precio_total: 5000,
      estado: "pendiente"
    )
  end

  test "debería crear un boleto válido con zona y compra" do
    boleto = @compra.boletos.new(zona: @zona, token_qr: SecureRandom.uuid, estado: "pendiente")
    assert boleto.valid?, "El boleto debería ser válido"
    assert boleto.save
  end

  test "no debería permitir boletos sin zona asociada" do
    boleto = @compra.boletos.new(token_qr: "QR-TEST", estado: "pendiente")
    assert_not boleto.save, "Guardó el boleto sin zona"
  end

  test "no debería permitir boletos sin compra asociada" do
    boleto = Boleto.new(zona: @zona, token_qr: "QR-TEST", estado: "pendiente")
    assert_not boleto.valid?, "El boleto debería ser inválido sin compra"
    assert_includes boleto.errors[:compra], "debe existir"
  end

  test "debería generar token_qr único por boleto" do
    boleto1 = @compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pendiente")
    boleto2 = @compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pendiente")
    assert_not_equal boleto1.token_qr, boleto2.token_qr, "Los token_qr no son únicos"
  end

  test "debería tener estado pendiente por defecto" do
    boleto = @compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid)
    assert_equal "pendiente", boleto.estado
  end

  test "debería poder cambiar estado a pagado" do
    boleto = @compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pendiente")
    boleto.update!(estado: "pagado")
    assert_equal "pagado", boleto.reload.estado
  end

  test "debería pertenecer a una zona" do
    boleto = @compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pendiente")
    assert_equal @zona, boleto.zona
  end

  test "al destruir la compra también se destruyen sus boletos" do
    @compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pendiente")
    assert_difference "Boleto.count", -1 do
      @compra.destroy
    end
  end
end
