require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "no debería guardar un usuario sin correo" do
    user = User.new(password: "password123", name: "Test User")
    assert_not user.save, "Guardó el usuario sin correo"
  end

  test "no debería permitir correos duplicados (HU-07)" do
    User.create!(email: "duplicate@test.com", password: "password123", name: "User 1")
    user2 = User.new(email: "duplicate@test.com", password: "password456", name: "User 2")
    assert_not user2.save, "Permitió registrar un correo ya existente"
  end

  test "la contraseña debería estar cifrada (HU-07)" do
    user = User.create!(email: "secure@test.com", password: "my_secret_password", name: "Secure User")
    assert_not_equal "my_secret_password", user.encrypted_password, "La contraseña no se guardó cifrada"
  end

  test "debería validar el formato del correo" do
    user = User.new(email: "correo-invalido", password: "password123")
    assert_not user.valid?, "Aceptó un correo con formato inválido"
  end

  test "debería aceptar un correo con formato válido" do
    user = User.new(email: "valido@correo.com", password: "password123", name: "Válido")
    assert user.valid?
  end

  test "debería tener muchas compras" do
    user = User.create!(email: "compras@test.com", password: "password123", name: "Comprador")
    user.compras.create!(cantidad: 1, numero_orden: "ORD-U1", precio_total: 5000, estado: "pendiente")
    user.compras.create!(cantidad: 2, numero_orden: "ORD-U2", precio_total: 10000, estado: "completado")
    assert_equal 2, user.compras.count
  end

  test "scope search_by_query debería encontrar por nombre" do
    User.create!(email: "juan@test.com", password: "password123", name: "Juan Pérez")
    User.create!(email: "ana@test.com", password: "password123", name: "Ana López")

    resultados = User.search_by_query("Juan")
    assert_equal 1, resultados.count
    assert_equal "Juan Pérez", resultados.first.name
  end

  test "scope search_by_query debería encontrar por email" do
    User.create!(email: "especial@empresa.com", password: "password123", name: "Especial")
    User.create!(email: "otro@test.com", password: "password123", name: "Otro")

    resultados = User.search_by_query("empresa")
    assert_equal 1, resultados.count
    assert_equal "especial@empresa.com", resultados.first.email
  end

  test "scope search_by_query debería ser case-insensitive" do
    User.create!(email: "maria@test.com", password: "password123", name: "María García")

    assert_equal 1, User.search_by_query("maría").count
    assert_equal 1, User.search_by_query("MARÍA").count
  end

  test "scope search_by_query debería retornar vacío sin coincidencias" do
    User.create!(email: "alguien@test.com", password: "password123", name: "Alguien")
    assert_equal 0, User.search_by_query("XYZ_INEXISTENTE").count
  end
end
