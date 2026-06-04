require "test_helper"

class EventoTest < ActiveSupport::TestCase

  def evento_valido(attrs = {})
    {
      nombre: "Evento Test", descripcion: "Desc",
      fecha: Date.tomorrow, hora: "20:00",
      imagen: "img.jpg", estado: "activo"
    }.merge(attrs)
  end

  test "agotado? es true cuando estado es cerrado" do
    evento = Evento.create!(evento_valido(estado: "cerrado"))
    assert evento.agotado?
  end

  test "agotado? es true cuando no tiene zonas" do
    evento = Evento.create!(evento_valido)
    # Sin zonas → zonas.none? → true
    assert evento.agotado?
  end

  test "agotado? es false cuando hay zonas con cupos disponibles" do
    evento = Evento.create!(evento_valido)
    evento.zonas.create!(nombre: "General", precio_cents: 50_000, capacidad: 100)
    assert_not evento.agotado?
  end

  test "agotado? es true cuando todas las zonas están llenas" do
    evento = Evento.create!(evento_valido)
    zona = evento.zonas.create!(nombre: "General", precio_cents: 50_000, capacidad: 1)
    user = User.create!(name: "Ana", email: "ana@test.com", password: "password123")
    compra = Compra.create!(
      user: user, email: user.email,
      numero_orden: "FA-AGOT-001", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
    compra.boletos.create!(
      zona: zona, nombre_zona: zona.nombre,
      nombre_evento: evento.nombre,
      token_qr: SecureRandom.uuid, estado: "pagado"
    )
    # Zona con 1 capacidad y 1 boleto → cupos_disponibles = 0
    assert evento.agotado?
  end

  # soft_delete!

  test "soft_delete! asigna deleted_at al evento" do
    evento = Evento.create!(evento_valido)
    evento.soft_delete!
    assert_not_nil evento.reload.deleted_at
  end

  test "soft_delete! cambia estado a cerrado" do
    evento = Evento.create!(evento_valido)
    evento.soft_delete!
    assert_equal "cerrado", evento.reload.estado
  end

  test "scope visible excluye eventos con deleted_at" do
    evento = Evento.create!(evento_valido)
    evento.soft_delete!
    assert_not Evento.visible.include?(evento)
  end

  test "eliminado? es true después de soft_delete!" do
    evento = Evento.create!(evento_valido)
    evento.soft_delete!
    assert evento.eliminado?
  end

  test "eliminado? es false para evento activo" do
    evento = Evento.create!(evento_valido)
    assert_not evento.eliminado?
  end

  test "search_by_name encuentra por nombre" do
    e = Evento.create!(nombre: "Rock Fest", descripcion: "Desc", fecha: Date.tomorrow, hora: "20:00", imagen: "img.jpg", estado: "activo")
    assert_includes Evento.search_by_name("Rock"), e
  end
end
