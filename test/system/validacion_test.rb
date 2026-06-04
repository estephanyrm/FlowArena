require "application_system_test_case"

class ValidacionTest < ApplicationSystemTestCase

  # Helpers

  def crear_boleto_pagado(usado: false)
    evento = Evento.create!(
      nombre:      "Evento QR Test",
      descripcion: "Para pruebas de validación.",
      fecha:       Date.today + 10,
      hora:        Time.parse("20:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "activo"
    )
    zona = evento.zonas.create!(
      nombre:      "VIP",
      precio_cents: 80_000,
      capacidad:   50
    )
    compra = Compra.create!(
      email:        "validacion@test.com",
      numero_orden: "FA-VAL-#{SecureRandom.hex(4).upcase}",
      cantidad:     1,
      precio_total: zona.precio_cents,
      estado:       "completado"
    )
    compra.boletos.create!(
      zona:         zona,
      nombre_zona:  zona.nombre,
      nombre_evento: evento.nombre,
      fecha_evento:  evento.fecha,
      hora_evento:   evento.hora,
      token_qr:     SecureRandom.uuid,
      estado:       "pagado",
      usado:        usado
    )
  end

  test "ST-12: token de boleto válido (pagado, no usado) muestra 'BOLETO VÁLIDO'" do
    boleto = crear_boleto_pagado(usado: false)

    visit validar_boleto_path(boleto.token_qr)

    assert_text "BOLETO VÁLIDO"
    assert_text "Listo para ingresar"
    assert_text "Evento QR Test"
    assert_text "VIP"
    assert_button "Confirmar ingreso"
  end

  test "ST-13: token inexistente muestra 'Este boleto no existe en el sistema'" do
    token_falso = "00000000-0000-0000-0000-000000000000"

    visit validar_boleto_path(token_falso)

    assert_text "BOLETO INVÁLIDO"
    assert_text "Este boleto no existe en el sistema"
  end

  test "ST-14: token de boleto ya usado muestra 'ya fue utilizado'" do
    boleto = crear_boleto_pagado(usado: true)

    visit validar_boleto_path(boleto.token_qr)

    assert_text "YA UTILIZADO"
    assert_text "Este boleto ya fue escaneado"
  end

end