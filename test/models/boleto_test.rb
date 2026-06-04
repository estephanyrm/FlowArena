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

  # Tests para token_qr único (RNF-04)
  test "no debería permitir dos boletos con el mismo token_qr" do
    @compra.boletos.create!(zona: @zona, token_qr: "token-duplicado", estado: "pendiente")
    assert_raises ActiveRecord::RecordNotUnique do
      @compra.boletos.create!(zona: @zona, token_qr: "token-duplicado", estado: "pendiente")
    end
  end

  # Tests para usado? (RF-08 / validación QR) 
  test "usado? retorna false cuando el boleto no ha sido usado" do
    boleto = @compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pagado")
    assert_not boleto.usado?, "El boleto no debería estar marcado como usado"
  end

  test "usado? retorna true cuando el boleto fue marcado como usado" do
    boleto = @compra.boletos.create!(zona: @zona, token_qr: SecureRandom.uuid, estado: "pagado")
    boleto.update!(usado: true)
    assert boleto.usado?, "El boleto debería estar marcado como usado"
  end

  test "snapshot helpers retornan datos del snapshot aunque el evento sea eliminado con soft-delete" do
    boleto = @compra.boletos.create!(
      zona: @zona,
      token_qr: SecureRandom.uuid,
      estado: "pagado",
      nombre_zona: "VIP",
      nombre_evento: "Festival Snapshot",
      fecha_evento: Date.tomorrow,
      hora_evento: Time.now
    )
    @evento.soft_delete!
    boleto.reload
    assert_equal "VIP", boleto.nombre_zona_safe
    assert_equal "Festival Snapshot", boleto.nombre_evento_safe
  end

  test "nombre_zona_safe retorna el snapshot si existe, aunque la zona viva también exista" do
    boleto = @compra.boletos.create!(
      zona: @zona, token_qr: SecureRandom.uuid,
      estado: "pagado", nombre_zona: "VIP Snapshot"
    )
    assert_equal "VIP Snapshot", boleto.nombre_zona_safe
  end
 
  test "nombre_zona_safe retorna el nombre de la zona viva cuando no hay snapshot" do
    boleto = @compra.boletos.create!(
      zona: @zona, token_qr: SecureRandom.uuid,
      estado: "pagado"
      # sin nombre_zona → nil
    )
    assert_equal @zona.nombre, boleto.nombre_zona_safe
  end
 
  test "nombre_evento_safe retorna el snapshot si existe" do
    boleto = @compra.boletos.create!(
      zona: @zona, token_qr: SecureRandom.uuid,
      estado: "pagado", nombre_evento: "Evento Snapshot"
    )
    assert_equal "Evento Snapshot", boleto.nombre_evento_safe
  end
 
  test "nombre_evento_safe retorna el nombre del evento vivo cuando no hay snapshot" do
    boleto = @compra.boletos.create!(
      zona: @zona, token_qr: SecureRandom.uuid, estado: "pagado"
    )
    assert_equal @evento.nombre, boleto.nombre_evento_safe
  end
 
  test "precio_boleto_safe retorna precio_boleto_cents si existe" do
    boleto = @compra.boletos.create!(
      zona: @zona, token_qr: SecureRandom.uuid,
      estado: "pagado", precio_boleto_cents: 99999
    )
    assert_equal 99999, boleto.precio_boleto_safe
  end
 
  test "precio_boleto_safe retorna el precio de la zona cuando no hay snapshot" do
    boleto = @compra.boletos.create!(
      zona: @zona, token_qr: SecureRandom.uuid, estado: "pagado"
    )
    assert_equal @zona.precio_cents, boleto.precio_boleto_safe
  end

  test "destruir la zona destruye sus boletos por dependent: :destroy" do
    boleto = @compra.boletos.create!(
      zona: @zona, token_qr: SecureRandom.uuid, estado: "pagado"
    )
    assert_difference "Boleto.count", -1 do
      @zona.destroy
    end
  end

  test "SecureRandom.uuid genera tokens únicos para múltiples boletos" do
    tokens = 5.times.map { SecureRandom.uuid }
    assert_equal 5, tokens.uniq.length, "SecureRandom.uuid produjo duplicados"
  end

end
