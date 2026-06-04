require "test_helper"

class ZonaTest < ActiveSupport::TestCase

  def setup
    @evento = Evento.create!(
      nombre: "Festival Zona", descripcion: "Desc",
      fecha: Date.tomorrow, hora: "20:00",
      imagen: "img.jpg", estado: "activo"
    )
  end

  def zona_valida(attrs = {})
    { nombre: "General", precio_cents: 50_000, capacidad: 100 }.merge(attrs)
  end

  # validar_precio_maximo

  test "precio_cents nulo es inválido" do
    zona = @evento.zonas.build(zona_valida(precio_cents: nil))
    assert_not zona.valid?
    assert zona.errors[:precio_cents].any?
  end

  test "precio_cents igual a 0 es inválido" do
    zona = @evento.zonas.build(zona_valida(precio_cents: 0))
    assert_not zona.valid?
    assert zona.errors[:precio_cents].any?
  end

  test "precio_cents negativo es inválido" do
    zona = @evento.zonas.build(zona_valida(precio_cents: -1))
    assert_not zona.valid?
    assert zona.errors[:precio_cents].any?
  end

  test "precio_cents mayor a 3.000.000 agrega error en :base" do
    zona = @evento.zonas.build(zona_valida(precio_cents: 3_000_001))
    assert_not zona.valid?
    assert zona.errors[:base].any?
    assert_match "máximo permitido", zona.errors[:base].first
  end

  test "precio_cents igual a 3.000.000 es válido" do
    zona = @evento.zonas.build(zona_valida(precio_cents: 3_000_000))
    assert zona.valid?, zona.errors.full_messages.join(", ")
  end

  test "precio_cents de 1 es válido" do
    zona = @evento.zonas.build(zona_valida(precio_cents: 1))
    assert zona.valid?, zona.errors.full_messages.join(", ")
  end

  # capacidad_dentro_del_tope

  test "capacidad nula es inválida" do
    zona = @evento.zonas.build(zona_valida(capacidad: nil))
    assert_not zona.valid?
    assert zona.errors[:capacidad].any?
  end

  test "capacidad 0 es inválida" do
    zona = @evento.zonas.build(zona_valida(capacidad: 0))
    assert_not zona.valid?
    assert zona.errors[:capacidad].any?
  end

  test "capacidad negativa es inválida" do
    zona = @evento.zonas.build(zona_valida(capacidad: -5))
    assert_not zona.valid?
    assert zona.errors[:capacidad].any?
  end

  test "General con capacidad mayor a 4000 es inválida" do
    zona = @evento.zonas.build(zona_valida(nombre: "General", capacidad: 4_001))
    assert_not zona.valid?
    assert zona.errors[:capacidad].any?
    assert_match "4000", zona.errors[:capacidad].first
  end

  test "VIP con capacidad mayor a 3000 es inválida" do
    zona = @evento.zonas.build(zona_valida(nombre: "VIP", capacidad: 3_001))
    assert_not zona.valid?
    assert zona.errors[:capacidad].any?
  end

  test "Diamante con capacidad mayor a 2000 es inválida" do
    zona = @evento.zonas.build(zona_valida(nombre: "Diamante", capacidad: 2_001))
    assert_not zona.valid?
    assert zona.errors[:capacidad].any?
  end

  test "Preferencial con capacidad igual al tope es válida" do
    zona = @evento.zonas.build(zona_valida(nombre: "Preferencial", capacidad: 3_000))
    assert zona.valid?, zona.errors.full_messages.join(", ")
  end

  # cupos_disponibles

  test "cupos_disponibles devuelve capacidad sin boletos" do
    zona = @evento.zonas.create!(zona_valida(capacidad: 50))
    assert_equal 50, zona.cupos_disponibles
  end

  test "cupos_disponibles decrementa al crear boletos" do
    zona = @evento.zonas.create!(zona_valida(capacidad: 50))
    user = User.create!(name: "Ana", email: "ana@test.com", password: "password123")
    compra = Compra.create!(
      user: user, email: user.email,
      numero_orden: "FA-CUPOS-001", cantidad: 3,
      precio_total: 150_000, estado: "completado"
    )
    3.times do
      compra.boletos.create!(
        zona: zona, nombre_zona: zona.nombre,
        nombre_evento: @evento.nombre,
        token_qr: SecureRandom.uuid, estado: "pagado"
      )
    end
    assert_equal 47, zona.reload.cupos_disponibles
  end

  test "no se puede crear zona con nombre duplicado en el mismo evento" do
    @evento.zonas.create!(zona_valida(nombre: "VIP"))
    zona_dup = @evento.zonas.build(zona_valida(nombre: "VIP"))
    assert_not zona_dup.valid?
    assert zona_dup.errors[:nombre].any?
  end

  test "se puede crear zona con mismo nombre en evento diferente" do
    otro_evento = Evento.create!(
      nombre: "Otro Evento", descripcion: "Desc",
      fecha: Date.tomorrow, hora: "18:00",
      imagen: "img2.jpg", estado: "activo"
    )
    @evento.zonas.create!(zona_valida(nombre: "VIP"))
    zona_otro = otro_evento.zonas.build(zona_valida(nombre: "VIP"))
    assert zona_otro.valid?, zona_otro.errors.full_messages.join(", ")
  end
end
