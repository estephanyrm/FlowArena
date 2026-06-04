require "application_system_test_case"

class ComprasTest < ApplicationSystemTestCase

  # Helpers
  def crear_evento_con_zona(nombre_evento: "Festival Test", zona_nombre: "General",
                             capacidad: 100, precio_cents: 50_000)
    evento = Evento.create!(
      nombre:      nombre_evento,
      descripcion: "Descripción de prueba para el evento.",
      fecha:       Date.today + 30,
      hora:        Time.parse("20:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "activo"
    )
    zona = evento.zonas.create!(
      nombre:      zona_nombre,
      precio_cents: precio_cents,
      capacidad:   capacidad
    )
    [ evento, zona ]
  end

  def login_como(user)
    visit new_user_session_path
    fill_in "E-Mail",     with: user.email
    fill_in "Contraseña", with: "password123"
    find("input[name='habeas_data']").check
    click_button "Ingresar"
    assert_text "Sesión iniciada correctamente."
  end

  test "ST-05: usuario autenticado completa pago con Efecty y ve confirmación" do
    user = User.create!(
      name:     "Compradora Test",
      email:    "compra@test.com",
      password: "password123"
    )
    evento, zona = crear_evento_con_zona

    login_como(user)

    # Ir directamente a la página de compra (simulando selección de zona vía formulario)
    # La vista de `new` usa un mapa SVG con JS; navegamos directamente al POST
    page.driver.browser.manage.add_cookie(name: "ultimo_email_compra", value: user.email)

    # Crear la compra directamente y visitar la página de pago
    compra = Compra.create!(
      user:         user,
      email:        user.email,
      numero_orden: "FA-TEST-#{SecureRandom.hex(4).upcase}",
      cantidad:     1,
      precio_total: zona.precio_cents,
      estado:       "pendiente"
    )
    compra.boletos.create!(
      zona:         zona,
      nombre_zona:  zona.nombre,
      nombre_evento: evento.nombre,
      token_qr:     SecureRandom.uuid,
      estado:       "pendiente"
    )

    visit pago_compra_path(compra)

    # Seleccionar Efecty (sin campos adicionales requeridos)
    click_button "Efecty"

    click_button "PAGAR AHORA →"

    assert_text "¡Pago exitoso! Tu boleto ha sido emitido."
  end

  test "ST-06: compra falla si se solicitan más cupos de los disponibles" do
    user = User.create!(
      name:     "Usuario Cupos",
      email:    "cupos@test.com",
      password: "password123"
    )
    evento, zona = crear_evento_con_zona(capacidad: 1)

    # Agotar el único cupo disponible con un boleto previo
    compra_existente = Compra.create!(
      user:         user,
      email:        user.email,
      numero_orden: "FA-PRE-#{SecureRandom.hex(4).upcase}",
      cantidad:     1,
      precio_total: zona.precio_cents,
      estado:       "pendiente"
    )
    compra_existente.boletos.create!(
      zona:         zona,
      nombre_zona:  zona.nombre,
      nombre_evento: evento.nombre,
      token_qr:     SecureRandom.uuid,
      estado:       "pendiente"
    )

    login_como(user)

    visit new_compra_path(evento_id: evento.id)

    # Poblar los campos hidden y hacer submit via JS, saltando el disabled del botón
    page.execute_script("document.getElementById('hidden-zona-id').value = '#{zona.id}'")
    page.execute_script("document.getElementById('hidden-cantidad').value = '2'")
    page.execute_script("document.getElementById('form-compra').submit()")

    assert_text "Lo sentimos, los cupos para esta zona se agotaron."
  end

  test "ST-07: usuario autenticado ve su historial en /mis_compras" do
    user = User.create!(
      name:     "Historico Test",
      email:    "historial@test.com",
      password: "password123"
    )
    evento, zona = crear_evento_con_zona(nombre_evento: "Concierto Historial")

    compra = Compra.create!(
      user:         user,
      email:        user.email,
      numero_orden: "FA-HIST-0001",
      cantidad:     2,
      precio_total: zona.precio_cents * 2,
      estado:       "completado"
    )
    2.times do
      compra.boletos.create!(
        zona:         zona,
        nombre_zona:  zona.nombre,
        nombre_evento: evento.nombre,
        token_qr:     SecureRandom.uuid,
        estado:       "pagado"
      )
    end

    login_como(user)
    visit mis_compras_path

    assert_text "Mis Boletos"
    assert_text "Concierto Historial"
  end

  test "ST-08: usuario no autenticado es redirigido al login al visitar /mis_compras" do
    visit mis_compras_path

    assert_current_path new_user_session_path
    assert_text "Debes iniciar sesión para ver tus compras."
  end

end