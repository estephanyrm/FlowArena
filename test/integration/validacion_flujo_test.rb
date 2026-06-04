require "test_helper"

class ValidacionFlujoTest < ActionDispatch::IntegrationTest
  def setup
    @evento = Evento.create!(
      nombre: "Festival Validación",
      descripcion: "Desc",
      fecha: Date.tomorrow,
      hora: Time.now,
      imagen: "img.jpg",
      estado: "activo"
    )
    @zona = @evento.zonas.create!(nombre: "General", capacidad: 100, precio_cents: 5000)
    @user = User.create!(email: "valida@test.com", password: "password123", name: "Validador")
    @compra = @user.compras.create!(
      cantidad: 1,
      numero_orden: "ORD-VAL-001",
      precio_total: 5000,
      estado: "completado",
      email: @user.email
    )
    @boleto = @compra.boletos.create!(
      zona: @zona,
      token_qr: SecureRandom.uuid,
      estado: "pagado",
      nombre_zona: @zona.nombre,
      nombre_evento: @evento.nombre,
      usado: false
    )
  end

  # GET /validar/:token

  test "muestra boleto válido con token correcto y estado pagado" do
    get validar_boleto_path(@boleto.token_qr)
    assert_response :success
    assert_match "BOLETO VÁLIDO", response.body
    assert_match @evento.nombre, response.body
  end

  test "muestra inválido con token inexistente" do
    get validar_boleto_path("token-que-no-existe")
    assert_response :success
    assert_match "BOLETO INVÁLIDO", response.body
  end

  test "muestra inválido si el boleto no está pagado" do
    @boleto.update!(estado: "pendiente")
    get validar_boleto_path(@boleto.token_qr)
    assert_response :success
    assert_match "BOLETO INVÁLIDO", response.body
  end

  test "muestra ya utilizado si el boleto fue marcado como usado" do
    @boleto.update!(usado: true)
    get validar_boleto_path(@boleto.token_qr)
    assert_response :success
    assert_match "YA UTILIZADO", response.body
  end

  # POST /validar/:token 

  test "confirmar ingreso marca el boleto como usado y redirige" do
    assert_not @boleto.usado?

    post confirmar_validacion_path(@boleto.token_qr)

    assert @boleto.reload.usado?, "El boleto debería quedar marcado como usado"
    assert_redirected_to validar_boleto_path(@boleto.token_qr)
  end

  test "no puede confirmar ingreso de un boleto ya usado" do
    @boleto.update!(usado: true)

    post confirmar_validacion_path(@boleto.token_qr)

    assert_redirected_to validar_boleto_path(@boleto.token_qr)
    assert_equal "No se puede marcar este boleto como usado.", flash[:alert]
  end

  test "no puede confirmar ingreso de un boleto no pagado" do
    @boleto.update!(estado: "pendiente")

    post confirmar_validacion_path(@boleto.token_qr)

    assert_redirected_to validar_boleto_path(@boleto.token_qr)
    assert_equal "No se puede marcar este boleto como usado.", flash[:alert]
  end

  test "no puede confirmar ingreso con token inexistente" do
    post confirmar_validacion_path("token-falso")
    assert_redirected_to validar_boleto_path("token-falso")
    assert_equal "No se puede marcar este boleto como usado.", flash[:alert]
  end

  # Acceso sin autenticación

  test "la página de validación es accesible sin iniciar sesión" do
    get validar_boleto_path(@boleto.token_qr)
    assert_response :success
  end
end