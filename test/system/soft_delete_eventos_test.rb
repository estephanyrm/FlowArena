require "application_system_test_case"

# Verifica que un evento eliminado desde el panel admin deja
# de aparecer en la home para los usuarios finales.
class SoftDeleteEventosTest < ApplicationSystemTestCase

  def setup
    @admin = Admin.create!(
      email:    "admin_sd@flowarena.com",
      password: "admin123"
    )
  end

  test "ST-15: evento eliminado via soft-delete desaparece de la home" do
    evento = Evento.create!(
      nombre:      "Concierto Para Eliminar",
      descripcion: "Este evento será eliminado.",
      fecha:       Date.today + 10,
      hora:        Time.parse("20:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "activo"
    )
    evento.zonas.create!(nombre: "General", precio_cents: 30_000, capacidad: 200)

    visit root_path
    assert_text "Concierto Para Eliminar"

    # Hacer soft-delete directo desde el modelo (equivalente a lo que haría el admin)
    evento.soft_delete!

    # El evento debe haber quedado marcado, no borrado físicamente
    assert_not_nil evento.reload.deleted_at

    # Un visitante ya no debe verlo en la home
    visit root_path
    assert_no_text "Concierto Para Eliminar"
  end

  test "ST-16: evento eliminado queda con estado cerrado en la base de datos" do
    evento = Evento.create!(
      nombre:      "Evento A Cerrar",
      descripcion: "Se cerrará al eliminarlo.",
      fecha:       Date.today + 5,
      hora:        Time.parse("19:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "activo"
    )

    # Soft-delete directo desde el modelo
    evento.soft_delete!

    evento.reload
    assert_equal "cerrado", evento.estado
    assert_not_nil evento.deleted_at
  end

  # Los boletos de un evento eliminado siguen siendo accesibles para el comprador.

  test "ST-17: boletos de evento eliminado siguen visibles en mis_compras" do
    user = User.create!(
      name:     "Comprador Soft",
      email:    "softbuyer@test.com",
      password: "password123"
    )
    evento = Evento.create!(
      nombre:      "Evento Con Boletos",
      descripcion: "Tiene boletos vendidos.",
      fecha:       Date.today + 15,
      hora:        Time.parse("21:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "activo"
    )
    zona = evento.zonas.create!(nombre: "VIP", precio_cents: 80_000, capacidad: 50)

    compra = Compra.create!(
      user:         user,
      email:        user.email,
      numero_orden: "FA-SD-#{SecureRandom.hex(4).upcase}",
      cantidad:     1,
      precio_total: zona.precio_cents,
      estado:       "completado"
    )
    compra.boletos.create!(
      zona:          zona,
      nombre_zona:   zona.nombre,
      nombre_evento: evento.nombre,
      token_qr:      SecureRandom.uuid,
      estado:        "pagado"
    )

    # Eliminar el evento vía soft-delete
    evento.soft_delete!

    # El usuario sigue viendo su compra en mis_compras
    sign_in user
    visit mis_compras_path

    assert_text "Mis Boletos"
    assert_text "Evento Con Boletos"
  end

end