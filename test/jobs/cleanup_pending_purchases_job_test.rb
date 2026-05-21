require "test_helper"

class CleanupPendingPurchasesJobTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "job@test.com",
      password: "password123",
      name: "Job Tester"
    )
  end

  #  Invitados 

  test "elimina compra pendiente antigua de invitado" do
    compra = Compra.create!(
      user: nil,
      email: "invitado@test.com",
      cantidad: 1,
      numero_orden: "ORD-INV-VIEJA",
      precio_total: 5000,
      estado: "pendiente"
    )
    compra.update_column(:created_at, 5.minutes.ago)

    assert_difference "Compra.count", -1 do
      CleanupPendingPurchasesJob.new.perform
    end
  end

  test "no elimina compra pendiente reciente de invitado" do
    Compra.create!(
      user: nil,
      email: "invitado@test.com",
      cantidad: 1,
      numero_orden: "ORD-INV-RECIENTE",
      precio_total: 5000,
      estado: "pendiente"
    )

    assert_no_difference "Compra.count" do
      CleanupPendingPurchasesJob.new.perform
    end
  end

  # Usuarios registrados 

  test "no elimina compra pendiente antigua de usuario registrado" do
    compra = @user.compras.create!(
      cantidad: 1,
      numero_orden: "ORD-USER-VIEJA",
      precio_total: 5000,
      estado: "pendiente"
    )
    compra.update_column(:created_at, 10.minutes.ago)

    assert_no_difference "Compra.count" do
      CleanupPendingPurchasesJob.new.perform
    end
  end

  #  Caso mixto 

  test "elimina solo la compra antigua del invitado en escenario mixto" do
    # Invitado antiguo — debe eliminarse
    inv_vieja = Compra.create!(
      user: nil,
      email: "inv@test.com",
      cantidad: 1,
      numero_orden: "ORD-MIX-INV",
      precio_total: 5000,
      estado: "pendiente"
    )
    inv_vieja.update_column(:created_at, 10.minutes.ago)

    # Invitado reciente — debe sobrevivir
    Compra.create!(
      user: nil,
      email: "inv2@test.com",
      cantidad: 1,
      numero_orden: "ORD-MIX-INV-REC",
      precio_total: 5000,
      estado: "pendiente"
    )

    # Usuario registrado antiguo — debe sobrevivir
    compra_user = @user.compras.create!(
      cantidad: 1,
      numero_orden: "ORD-MIX-USER",
      precio_total: 5000,
      estado: "pendiente"
    )
    compra_user.update_column(:created_at, 10.minutes.ago)

    assert_difference "Compra.count", -1 do
      CleanupPendingPurchasesJob.new.perform
    end

    assert Compra.exists?(numero_orden: "ORD-MIX-INV-REC"),
           "La compra reciente del invitado no debió eliminarse"
    assert Compra.exists?(numero_orden: "ORD-MIX-USER"),
           "La compra del usuario registrado no debió eliminarse"
  end
end