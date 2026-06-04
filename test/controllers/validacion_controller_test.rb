require "test_helper"

class ValidacionControllerTest < ActionDispatch::IntegrationTest

  def setup
    @evento = Evento.create!(
      nombre: "Festival", descripcion: "Desc",
      fecha: Date.tomorrow, hora: "20:00",
      imagen: "img.jpg", estado: "activo"
    )
    @zona = @evento.zonas.create!(nombre: "General", precio_cents: 50_000, capacidad: 100)
    @user = User.create!(name: "Ana", email: "ana@test.com", password: "password123")
    @compra = Compra.create!(
      user: @user, email: @user.email,
      numero_orden: "FA-VAL-001", cantidad: 1,
      precio_total: 50_000, estado: "completado"
    )
  end

  def crear_boleto(estado: "pagado", usado: false)
    @compra.boletos.create!(
      zona: @zona, nombre_zona: @zona.nombre,
      nombre_evento: @evento.nombre,
      token_qr: SecureRandom.uuid, estado: estado, usado: usado
    )
  end

  test "show con token inexistente responde con éxito y muestra mensaje de error" do
    get validar_boleto_path("token-inexistente-xyz")
    assert_response :success
    assert_match "no existe", response.body
  end

  test "show con boleto en estado pendiente muestra mensaje de no pagado" do
    boleto = crear_boleto(estado: "pendiente")
    get validar_boleto_path(boleto.token_qr)
    assert_response :success
    assert_match "pagado", response.body
  end

  test "show con boleto cancelado muestra mensaje inválido" do
    boleto = crear_boleto(estado: "cancelado")
    get validar_boleto_path(boleto.token_qr)
    assert_response :success
    assert_match "pagado", response.body
  end

  test "show con boleto ya usado muestra mensaje de ya utilizado" do
    boleto = crear_boleto(estado: "pagado", usado: true)
    get validar_boleto_path(boleto.token_qr)
    assert_response :success
    assert_match "YA UTILIZADO", response.body
  end

  test "show con boleto pagado y no usado muestra mensaje válido" do
    boleto = crear_boleto(estado: "pagado", usado: false)
    get validar_boleto_path(boleto.token_qr)
    assert_response :success
    assert_match "VÁLIDO", response.body
  end

  test "confirmar marca boleto como usado y redirige" do
    boleto = crear_boleto(estado: "pagado", usado: false)
    post confirmar_validacion_path(boleto.token_qr)
    assert_equal true, boleto.reload.usado
    assert_redirected_to validar_boleto_path(boleto.token_qr)
    assert_match "Ingreso registrado", flash[:notice]
  end

  test "confirmar boleto ya usado redirige con alert" do
    boleto = crear_boleto(estado: "pagado", usado: true)
    post confirmar_validacion_path(boleto.token_qr)
    assert_redirected_to validar_boleto_path(boleto.token_qr)
    assert_match "No se puede", flash[:alert]
  end

  test "confirmar boleto no pagado redirige con alert" do
    boleto = crear_boleto(estado: "pendiente", usado: false)
    post confirmar_validacion_path(boleto.token_qr)
    assert_redirected_to validar_boleto_path(boleto.token_qr)
    assert_match "No se puede", flash[:alert]
  end

  test "confirmar token inexistente redirige con alert" do
    post confirmar_validacion_path("token-no-existe")
    assert_redirected_to validar_boleto_path("token-no-existe")
    assert_match "No se puede", flash[:alert]
  end
end