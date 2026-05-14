require "test_helper"

class ZonaTest < ActiveSupport::TestCase
  def setup
    @evento = Evento.create!(
      nombre: "Evento Test",
      descripcion: "Descripción",
      fecha: Date.tomorrow,
      hora: Time.now,
      imagen: "img.jpg",
      estado: "activo"
    )
  end

  test "no debería permitir zona con capacidad negativa" do
    zona = @evento.zonas.new(nombre: "VIP", capacidad: -1, precio_cents: 10000)
    assert_not zona.save, "Permitió crear una zona con capacidad negativa"
  end

  test "no debería permitir zona con capacidad cero" do
    zona = @evento.zonas.new(nombre: "VIP", capacidad: 0, precio_cents: 10000)
    assert_not zona.valid?
  end

  test "no debería permitir nombres de zona duplicados en el mismo evento" do
    @evento.zonas.create!(nombre: "General", capacidad: 100, precio_cents: 5000)
    zona_duplicada = @evento.zonas.new(nombre: "General", capacidad: 50, precio_cents: 8000)
    assert_not zona_duplicada.save, "Permitió duplicar el nombre de la zona en el mismo evento"
    assert_includes zona_duplicada.errors[:nombre], "esta zona ya ha sido registrada para este evento"
  end

  test "debería permitir el mismo nombre de zona en eventos distintos" do
    evento2 = Evento.create!(nombre: "Otro Evento", descripcion: "Desc", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")
    @evento.zonas.create!(nombre: "VIP", capacidad: 100, precio_cents: 5000)
    zona2 = evento2.zonas.new(nombre: "VIP", capacidad: 200, precio_cents: 8000)
    assert zona2.valid?, "Debería permitir la misma zona en distintos eventos"
  end

  test "no debería crear zona sin nombre" do
    zona = @evento.zonas.new(capacidad: 100, precio_cents: 5000)
    assert_not zona.valid?
    assert zona.errors[:nombre].present?
  end

  test "no debería crear zona sin evento" do
    zona = Zona.new(nombre: "General", capacidad: 100, precio_cents: 5000)
    assert_not zona.valid?
    assert_includes zona.errors[:evento], "debe existir"
  end

  test "debería calcular correctamente los cupos disponibles sin boletos" do
    zona = @evento.zonas.create!(nombre: "VIP", capacidad: 10, precio_cents: 20000)
    assert_equal 10, zona.cupos_disponibles
  end

  test "debería descontar boletos al calcular cupos disponibles" do
    zona = @evento.zonas.create!(nombre: "General", capacidad: 5, precio_cents: 3000)
    user = User.create!(email: "z@test.com", password: "password123", name: "Z")
    compra = user.compras.create!(cantidad: 2, numero_orden: "ORD-ZC", precio_total: 6000, estado: "pendiente")
    2.times { compra.boletos.create!(zona: zona, token_qr: SecureRandom.uuid, estado: "pendiente") }
    assert_equal 3, zona.cupos_disponibles
  end

  test "cupos_disponibles debería ser cero cuando la zona está llena" do
    zona = @evento.zonas.create!(nombre: "Diamante", capacidad: 1, precio_cents: 50000)
    user = User.create!(email: "full@test.com", password: "password123", name: "Full")
    compra = user.compras.create!(cantidad: 1, numero_orden: "ORD-FULL", precio_total: 50000, estado: "pendiente")
    compra.boletos.create!(zona: zona, token_qr: SecureRandom.uuid, estado: "pendiente")
    assert_equal 0, zona.cupos_disponibles
  end

  test "debería pertenecer a un evento" do
    zona = @evento.zonas.create!(nombre: "Preferencial", capacidad: 50, precio_cents: 7000)
    assert_equal @evento, zona.evento
  end

  test "debería tener muchos boletos" do
    zona = @evento.zonas.create!(nombre: "General", capacidad: 100, precio_cents: 3000)
    user = User.create!(email: "many@test.com", password: "password123", name: "Many")
    compra = user.compras.create!(cantidad: 3, numero_orden: "ORD-MANY", precio_total: 9000, estado: "pendiente")
    3.times { compra.boletos.create!(zona: zona, token_qr: SecureRandom.uuid, estado: "pendiente") }
    assert_equal 3, zona.boletos.count
  end

  test "la constante CAPACIDADES debe incluir las zonas permitidas" do
    assert_includes Zona::CAPACIDADES.keys, "Diamante"
    assert_includes Zona::CAPACIDADES.keys, "VIP"
    assert_includes Zona::CAPACIDADES.keys, "Preferencial"
    assert_includes Zona::CAPACIDADES.keys, "General"
  end

  test "ZONAS_PERMITIDAS debe ser el mismo listado que las claves de CAPACIDADES" do
    assert_equal Zona::CAPACIDADES.keys, Zona::ZONAS_PERMITIDAS
  end
end
