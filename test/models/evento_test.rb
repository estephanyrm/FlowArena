require "test_helper"

class EventoTest < ActiveSupport::TestCase

  test "no debería guardar un evento sin nombre" do
    evento = Evento.new(descripcion: "Desc", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")
    assert_not evento.save, "Guardó el evento sin nombre"
    assert_includes evento.errors[:nombre], "no puede estar en blanco"
  end

  test "no debería guardar un evento sin descripción" do
    evento = Evento.new(nombre: "Test", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")
    assert_not evento.save
    assert_includes evento.errors[:descripcion], "no puede estar en blanco"
  end

  test "no debería guardar un evento sin imagen" do
    evento = Evento.new(nombre: "Test", descripcion: "Desc", fecha: Date.tomorrow, hora: Time.now, estado: "activo")
    assert_not evento.save
    assert_includes evento.errors[:imagen], "no puede estar en blanco"
  end

  test "no debería guardar un evento sin hora" do
    evento = Evento.new(nombre: "Test", descripcion: "Desc", fecha: Date.tomorrow, imagen: "img.jpg", estado: "activo")
    assert_not evento.save
    assert_includes evento.errors[:hora], "no puede estar en blanco"
  end

  test "debería aceptar estado activo" do
    evento = Evento.new(nombre: "Test", descripcion: "Desc", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")
    assert evento.valid?
  end

  test "debería aceptar estado cerrado" do
    evento = Evento.new(nombre: "Test", descripcion: "Desc", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "cerrado")
    assert evento.valid?
  end

  test "no debería aceptar estados inválidos" do
    evento = Evento.new(nombre: "Test", descripcion: "Desc", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "cancelado")
    assert_not evento.valid?
    assert_includes evento.errors[:estado], "valor no permitido"
  end

  test "no debería permitir fechas pasadas al crear" do
    evento = Evento.new(nombre: "Pasado", descripcion: "Desc", fecha: Date.yesterday, hora: Time.now, imagen: "img.jpg", estado: "activo")
    assert_not evento.save, "Permitió crear un evento con fecha pasada"
    assert_includes evento.errors[:fecha], "no puede ser una fecha pasada"
  end

  test "debería permitir la fecha de hoy al crear" do
    evento = Evento.new(nombre: "Hoy", descripcion: "Desc", fecha: Date.today, hora: Time.now, imagen: "img.jpg", estado: "activo")
    assert evento.valid?
  end

  test "debería permitir actualizar un evento existente sin validar fecha pasada" do
    evento = Evento.create!(nombre: "Evento Futuro", descripcion: "Desc", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")
    # Cambiar solo el nombre no debería disparar la validación de fecha
    evento.update_column(:fecha, Date.yesterday)
    evento.reload
    evento.nombre = "Nombre Actualizado"
    assert evento.valid?  # La validación on: :create no aplica en update
  end

  test "debería buscar correctamente con el scope search_by_name por nombre" do
    Evento.create!(nombre: "Concierto Rock", descripcion: "Gran concierto", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")
    Evento.create!(nombre: "Feria Gastronómica", descripcion: "Comida", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")

    resultados = Evento.search_by_name("Rock")
    assert_equal 1, resultados.count
    assert_equal "Concierto Rock", resultados.first.nombre
  end

  test "debería buscar por descripción también" do
    Evento.create!(nombre: "Festival", descripcion: "Música electrónica en vivo", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")
    Evento.create!(nombre: "Teatro", descripcion: "Drama clásico", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")

    resultados = Evento.search_by_name("electrónica")
    assert_equal 1, resultados.count
    assert_equal "Festival", resultados.first.nombre
  end

  test "search_by_name debería ser case-insensitive" do
    Evento.create!(nombre: "Jazz Night", descripcion: "Una noche de jazz", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")

    assert_equal 1, Evento.search_by_name("jazz").count
    assert_equal 1, Evento.search_by_name("JAZZ").count
    assert_equal 1, Evento.search_by_name("Jazz").count
  end

  test "search_by_name debería retornar vacío cuando no hay coincidencias" do
    Evento.create!(nombre: "Concierto", descripcion: "Desc", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")
    assert_equal 0, Evento.search_by_name("Opera").count
  end

  test "debería tener muchas zonas" do
    evento = Evento.create!(nombre: "Multi-zona", descripcion: "Desc", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")
    evento.zonas.create!(nombre: "VIP", capacidad: 100, precio_cents: 10000)
    evento.zonas.create!(nombre: "General", capacidad: 500, precio_cents: 3000)
    assert_equal 2, evento.zonas.count
  end

  test "al destruir un evento también se destruyen sus zonas" do
    evento = Evento.create!(nombre: "Para Borrar", descripcion: "Desc", fecha: Date.tomorrow, hora: Time.now, imagen: "img.jpg", estado: "activo")
    evento.zonas.create!(nombre: "VIP", capacidad: 50, precio_cents: 5000)
    assert_difference "Zona.count", -1 do
      evento.destroy
    end
  end
end