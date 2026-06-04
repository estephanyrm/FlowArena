require "application_system_test_case"

class EventosTest < ApplicationSystemTestCase

  test "ST-09: la home lista eventos activos" do
    evento1 = Evento.create!(
      nombre:      "Concierto Activo Uno",
      descripcion: "Gran noche de música.",
      fecha:       Date.today + 10,
      hora:        Time.parse("19:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "activo"
    )
    evento1.zonas.create!(nombre: "General", precio_cents: 30_000, capacidad: 500)

    Evento.create!(
      nombre:      "Evento Cerrado",
      descripcion: "Evento fuera de venta.",
      fecha:       Date.today + 15,
      hora:        Time.parse("21:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "cerrado"
    )

    visit root_path

    assert_text "Concierto Activo Uno"
    assert_no_text "Evento Cerrado"
  end

  test "ST-10: el buscador filtra eventos por nombre" do
    Evento.create!(
      nombre:      "Rock en vivo",
      descripcion: "Noche de rock clásico.",
      fecha:       Date.today + 20,
      hora:        Time.parse("20:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "activo"
    )
    Evento.create!(
      nombre:      "Festival de Jazz",
      descripcion: "Lo mejor del jazz local.",
      fecha:       Date.today + 25,
      hora:        Time.parse("19:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "activo"
    )

    visit root_path

    fill_in "buscar", with: "Rock"
    find("form").native.submit

    assert_text "Rock en vivo"
    assert_no_text "Festival de Jazz"
    assert_text "Resultados para: Rock"
  end

  test "ST-11: un evento agotado muestra texto 'Sin entradas disponibles'" do
    evento_agotado = Evento.create!(
      nombre:      "Evento Agotado Total",
      descripcion: "Todas las entradas vendidas.",
      fecha:       Date.today + 5,
      hora:        Time.parse("18:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "cerrado"
    )

    visit root_path

    # El evento cerrado no aparece en la home (solo se listan activos).
    # Un evento activo pero con todas las zonas sin cupos sí aparece marcado.
    evento_sin_cupos = Evento.create!(
      nombre:      "Concierto Sin Cupos",
      descripcion: "Cupos agotados en todas las zonas.",
      fecha:       Date.today + 7,
      hora:        Time.parse("21:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "activo"
    )
    zona = evento_sin_cupos.zonas.create!(
      nombre:      "General",
      precio_cents: 20_000,
      capacidad:   1
    )

    # Crear un boleto para agotar el único cupo disponible
    compra = Compra.create!(
      email:        "test@agotado.com",
      numero_orden: "FA-AGO-#{SecureRandom.hex(4).upcase}",
      cantidad:     1,
      precio_total: zona.precio_cents,
      estado:       "completado"
    )
    compra.boletos.create!(
      zona:         zona,
      nombre_zona:  zona.nombre,
      nombre_evento: evento_sin_cupos.nombre,
      token_qr:     SecureRandom.uuid,
      estado:       "pagado"
    )

    visit root_path

    assert_text "Concierto Sin Cupos"
    assert_text "Sin entradas disponibles"
    # Badge visible en la tarjeta del evento (texto en mayúsculas)
    assert_text "AGOTADO"
  end

end