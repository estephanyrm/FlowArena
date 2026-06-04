require "test_helper"

class CleanupPendingPurchasesJobTest < ActiveJob::TestCase

  def setup
    @evento = Evento.create!(
      nombre: "Festival Job", descripcion: "Desc",
      fecha: Date.tomorrow, hora: "20:00",
      imagen: "img.jpg", estado: "activo"
    )
    @zona = @evento.zonas.create!(nombre: "General", precio_cents: 50_000, capacidad: 100)
  end

  test "cancela compras pendientes de invitados creadas hace más de 2 minutos" do
    compra_vieja = Compra.create!(
      user: nil, email: "viejo@test.com",
      numero_orden: "FA-JOB-001", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    compra_vieja.update_column(:created_at, 3.minutes.ago)

    assert_difference "Compra.count", -1 do
      CleanupPendingPurchasesJob.perform_now
    end
  end

  test "no elimina compras pendientes de invitados recientes" do
    Compra.create!(
      user: nil, email: "reciente@test.com",
      numero_orden: "FA-JOB-002", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )

    assert_no_difference "Compra.count" do
      CleanupPendingPurchasesJob.perform_now
    end
  end

  test "no elimina compras completadas de invitados antiguas" do
    compra = Compra.create!(
      user: nil, email: "comp@test.com",
      numero_orden: "FA-JOB-003", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
    compra.update_column(:created_at, 10.minutes.ago)

    assert_no_difference "Compra.count" do
      CleanupPendingPurchasesJob.perform_now
    end
  end

  test "no elimina compras pendientes de usuarios registrados" do
    user = User.create!(name: "Reg", email: "reg@test.com", password: "password123")
    compra = Compra.create!(
      user: user, email: user.email,
      numero_orden: "FA-JOB-004", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    compra.update_column(:created_at, 10.minutes.ago)

    assert_no_difference "Compra.count" do
      CleanupPendingPurchasesJob.perform_now
    end
  end

  test "elimina múltiples compras viejas de invitados en un solo run" do
    3.times do |i|
      c = Compra.create!(
        user: nil, email: "multi#{i}@test.com",
        numero_orden: "FA-JOB-10#{i}", cantidad: 1,
        precio_total: 50_000, estado: "pendiente"
      )
      c.update_column(:created_at, 5.minutes.ago)
    end

    assert_difference "Compra.count", -3 do
      CleanupPendingPurchasesJob.perform_now
    end
  end
end