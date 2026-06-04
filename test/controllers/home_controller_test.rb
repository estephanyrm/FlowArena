require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest

  def setup
    @evento = Evento.create!(
      nombre: "Festival", descripcion: "Desc",
      fecha: Date.tomorrow, hora: "20:00",
      imagen: "http://example.com/img.jpg",  # ← URL externa, no asset local
      estado: "activo"
    )
    @zona = @evento.zonas.create!(nombre: "General", precio_cents: 10_000, capacidad: 50)
  end

  test "index filtra eventos por buscar" do
    get root_path, params: { buscar: "Festival" }
    assert_response :success
    assert_match "Festival", response.body
  end

  test "pagina_eventos muestra el evento si existe" do
    get pagina_eventos_path(id: @evento.id)
    assert_response :success
  end

  test "pagina_eventos redirige si el evento no existe" do
    get pagina_eventos_path(id: 999999)
    assert_redirected_to root_path
    assert_match "Evento no encontrado", flash[:alert]
  end
end