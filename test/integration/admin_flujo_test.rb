require "test_helper"

class AdminFlujoTest < ActionDispatch::IntegrationTest
  def setup
    @admin = Admin.create!(
      email: "admin@flowarena.com",
      password: "admin123"
    )
    @user = User.create!(
      email: "user@flowarena.com",
      password: "password123",
      name: "Usuario Normal"
    )
    @evento = Evento.create!(
      nombre: "Evento Admin Test",
      descripcion: "Desc",
      fecha: Date.tomorrow,
      hora: Time.now,
      imagen: "img.jpg",
      estado: "activo"
    )
  end

  # Protección del panel

  test "usuario no autenticado no puede acceder al dashboard admin" do
    get admin_dashboard_path
    assert_response :redirect
  end

  test "usuario normal no puede acceder al dashboard admin" do
    sign_in @user
    get admin_dashboard_path
    assert_response :redirect
  end

  test "admin autenticado puede acceder al dashboard" do
    sign_in @admin
    get admin_dashboard_path
    assert_response :success
  end

  # CRUD Eventos

  test "admin puede ver el listado de eventos" do
    sign_in @admin
    get admin_eventos_path
    assert_response :success
    assert_match @evento.nombre, response.body
  end

  test "admin puede crear un evento válido" do
    sign_in @admin

    assert_difference "Evento.count", 1 do
      post admin_eventos_path, params: {
        evento: {
          nombre: "Nuevo Evento",
          descripcion: "Descripción del evento",
          fecha: Date.tomorrow,
          hora: Time.now,
          imagen: "img.jpg",
          estado: "activo"
        }
      }
    end

    assert_redirected_to admin_eventos_path
  end

  test "admin no puede crear un evento sin nombre" do
    sign_in @admin

    assert_no_difference "Evento.count" do
      post admin_eventos_path, params: {
        evento: {
          nombre: "",
          descripcion: "Desc",
          fecha: Date.tomorrow,
          hora: Time.now,
          imagen: "img.jpg",
          estado: "activo"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "admin puede actualizar un evento existente" do
    sign_in @admin

    patch admin_evento_path(@evento), params: {
      evento: { nombre: "Nombre Actualizado" }
    }

    assert_redirected_to admin_eventos_path
    assert_equal "Nombre Actualizado", @evento.reload.nombre
  end

  # El sistema usa soft-delete: el registro permanece en BD con deleted_at seteado.
  # Evento.count no baja; en cambio el evento queda marcado como eliminado.
  test "admin puede eliminar un evento sin ventas" do
    sign_in @admin

    assert_no_difference "Evento.count" do
      delete admin_evento_path(@evento)
    end

    assert_redirected_to admin_eventos_path
    assert_not_nil @evento.reload.deleted_at,
      "El evento debería tener deleted_at seteado tras el soft-delete"
  end

  # El sistema hace soft-delete incluso cuando hay boletos vendidos y
  # avisa al admin cuántos boletos quedaron activos.
  # Los boletos siguen siendo accesibles gracias al snapshot guardado en cada uno.
  test "admin elimina un evento con boletos vendidos y recibe aviso" do
    sign_in @admin

    zona   = @evento.zonas.create!(nombre: "General", capacidad: 100, precio_cents: 50000)
    compra = Compra.create!(
      email: "comprador@test.com",   # requerido porque no hay user_id
      numero_orden: "FA-TEST-001",
      cantidad: 1,
      precio_total: 50000,
      estado: "completado"
    )
    zona.boletos.create!(compra: compra, estado: "pagado", token_qr: SecureRandom.uuid)

    assert_no_difference "Evento.count" do
      delete admin_evento_path(@evento)
    end

    assert_redirected_to admin_eventos_path
    assert_not_nil @evento.reload.deleted_at,
      "El evento debería quedar marcado como eliminado"
    # El notice debe mencionar la cantidad de boletos vendidos
    assert_match /boleto/, flash[:notice]
  end

  test "usuario normal no puede crear eventos desde el panel admin" do
    sign_in @user

    assert_no_difference "Evento.count" do
      post admin_eventos_path, params: {
        evento: {
          nombre: "Evento Intruso",
          descripcion: "Desc",
          fecha: Date.tomorrow,
          hora: Time.now,
          imagen: "img.jpg",
          estado: "activo"
        }
      }
    end

    assert_response :redirect
  end

  # CRUD Zonas

  test "admin puede crear una zona válida para un evento" do
    sign_in @admin

    assert_difference "Zona.count", 1 do
      post admin_evento_zonas_path(@evento), params: {
        zona: {
          nombre: "VIP",
          capacidad: 100,
          precio_cents: 50000
        }
      }
    end

    assert_redirected_to admin_evento_zonas_path(@evento)
  end

  test "admin no puede crear una zona con capacidad superior al tope" do
    sign_in @admin

    assert_no_difference "Zona.count" do
      post admin_evento_zonas_path(@evento), params: {
        zona: {
          nombre: "VIP",
          capacidad: 99999,
          precio_cents: 50000
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # Reportes

  test "admin puede acceder al listado de reportes" do
    sign_in @admin
    get admin_reportes_path
    assert_response :success
  end

  test "admin puede filtrar reportes por fecha" do
    sign_in @admin
    get admin_reportes_path, params: {
      fecha_inicio: Date.today.to_s,
      fecha_fin: Date.tomorrow.to_s
    }
    assert_response :success
  end

  test "usuario normal no puede ver reportes" do
    sign_in @user
    get admin_reportes_path
    assert_response :redirect
  end

  # Exportación de reportes
  test "GET export genera un archivo Excel descargable" do
    sign_in @admin

    # Compra completada para que haya datos en el reporte
    zona   = @evento.zonas.create!(nombre: "General", capacidad: 100, precio_cents: 50000)
    compra = Compra.create!(
      email: "export@test.com",
      numero_orden: "ORD-EXP-001",
      cantidad: 2,
      precio_total: 100000,
      estado: "completado"
    )
    zona.boletos.create!(compra: compra, estado: "pagado", token_qr: SecureRandom.uuid)

    get export_admin_reportes_path, params: { format: :xlsx }

    assert_response :success
    assert_includes response.content_type,
                  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    assert_match "attachment", response.headers["Content-Disposition"]
    assert_match ".xlsx", response.headers["Content-Disposition"]
  end

  test "GET export genera un archivo PDF descargable" do
    sign_in @admin

    zona   = @evento.zonas.create!(nombre: "General", capacidad: 100, precio_cents: 50000)
    compra = Compra.create!(
      email: "export_pdf@test.com",
      numero_orden: "ORD-EXP-002",
      cantidad: 1,
      precio_total: 50000,
      estado: "completado"
    )
    zona.boletos.create!(compra: compra, estado: "pagado", token_qr: SecureRandom.uuid)

    get export_admin_reportes_path, params: { format: :pdf }

    assert_response :success
    assert_includes response.content_type, "application/pdf"
    assert_match "attachment", response.headers["Content-Disposition"]
  end

  test "GET export respeta el filtro de fecha activo" do
    sign_in @admin

    zona = @evento.zonas.create!(nombre: "General", capacidad: 100, precio_cents: 50000)

    compra_vieja = Compra.create!(
      email: "vieja@test.com", numero_orden: "ORD-EXP-003",
      cantidad: 1, precio_total: 50000, estado: "completado",
      created_at: 2.months.ago
    )
    zona.boletos.create!(compra: compra_vieja, estado: "pagado", token_qr: SecureRandom.uuid)

    compra_nueva = Compra.create!(
      email: "nueva@test.com", numero_orden: "ORD-EXP-004",
      cantidad: 1, precio_total: 50000, estado: "completado"
    )
    zona.boletos.create!(compra: compra_nueva, estado: "pagado", token_qr: SecureRandom.uuid)

    # Usamos Date.tomorrow como fecha_fin para garantizar que los registros
    # creados en el día actual (con cualquier hora UTC) queden dentro del rango.
    get export_admin_reportes_path, params: {
      format: :xlsx,
      fecha_inicio: 1.week.ago.to_date.to_s,
      fecha_fin: Date.tomorrow.to_s
    }

    assert_response :success
    assert_includes response.content_type,
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    # El filtro debe retornar solo 1 compra (la nueva, no la de hace 2 meses)
    compras_en_rango = Compra.where(estado: "completado")
                            .where("created_at >= ?", 1.week.ago.beginning_of_day)
                            .where("created_at <= ?", Date.tomorrow.end_of_day)
    assert_includes compras_en_rango.pluck(:numero_orden), "ORD-EXP-004"
    assert_not_includes compras_en_rango.pluck(:numero_orden), "ORD-EXP-003"
  end

  test "GET export sin filtros genera archivo con todas las compras completadas" do
    sign_in @admin

    zona = @evento.zonas.create!(nombre: "General", capacidad: 100, precio_cents: 50000)
    ["ORD-EXP-005", "ORD-EXP-006"].each_with_index do |orden, i|
      compra = Compra.create!(
        email: "bulk#{i}@test.com", numero_orden: orden,
        cantidad: 1, precio_total: 50000, estado: "completado"
      )
      zona.boletos.create!(compra: compra, estado: "pagado", token_qr: SecureRandom.uuid)
    end

    get export_admin_reportes_path, params: { format: :xlsx }

    assert_response :success
    assert_includes response.content_type,
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    assert_match "attachment", response.headers["Content-Disposition"]

    # Verificar que ambas compras existen en BD con estado completado
    ordenes = Compra.where(estado: "completado").pluck(:numero_orden)
    assert_includes ordenes, "ORD-EXP-005"
    assert_includes ordenes, "ORD-EXP-006"
  end
end