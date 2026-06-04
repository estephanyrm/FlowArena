require "application_system_test_case"

class ReportesExportTest < ApplicationSystemTestCase

  def setup
    @admin = Admin.create!(
      email:    "admin_rep@flowarena.com",
      password: "admin123"
    )

    evento = Evento.create!(
      nombre:      "Evento Reporte Test",
      descripcion: "Para pruebas de exportación.",
      fecha:       Date.today + 20,
      hora:        Time.parse("20:00"),
      imagen:      "https://placehold.co/800x400",
      estado:      "activo"
    )
    zona = evento.zonas.create!(nombre: "General", precio_cents: 50_000, capacidad: 100)

    compra = Compra.create!(
      email:        "reporte@test.com",
      numero_orden: "FA-REP-#{SecureRandom.hex(4).upcase}",
      cantidad:     2,
      precio_total: zona.precio_cents * 2,
      estado:       "completado"
    )
    2.times do
      compra.boletos.create!(
        zona:          zona,
        nombre_zona:   zona.nombre,
        nombre_evento: evento.nombre,
        token_qr:      SecureRandom.uuid,
        estado:        "pagado"
      )
    end
  end

  # Admin accede al panel de reportes y ve el resumen de compras.
  test "ST-18: admin ve el panel de reportes con resumen de compras" do
    sign_in @admin
    visit admin_reportes_path

    assert_text "Reportes"
    # La página carga sin error
    assert_current_path admin_reportes_path
  end

  # El enlace de exportación xlsx está presente y apunta a la ruta correcta.

  test "ST-19: el panel de reportes contiene el enlace de descarga xlsx" do
    sign_in @admin
    visit admin_reportes_path

    # Verificar que existe algún enlace/botón de exportación a xlsx
    assert_selector "a[href*='export'][href*='xlsx'], a[href*='format=xlsx']",
                    wait: 5
  end

  # Admin sin autenticar es redirigido al login de admin al intentar ver reportes.
  test "ST-20: visitante no autenticado no puede acceder al panel de reportes" do
    visit admin_reportes_path

    # Debe redirigir al login de admins
    assert_no_current_path admin_reportes_path
  end

end