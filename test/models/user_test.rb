require "test_helper"

class UserTest < ActiveSupport::TestCase

  # search_by_query
  test "search_by_query encuentra por nombre parcial" do
    user = User.create!(name: "Carlos Ruiz", email: "carlos@test.com", password: "password123")
    resultados = User.search_by_query("Carlos")
    assert_includes resultados, user
  end

  test "search_by_query encuentra por email parcial" do
    user = User.create!(name: "Diana", email: "diana@correo.com", password: "password123")
    resultados = User.search_by_query("diana@correo")
    assert_includes resultados, user
  end

  test "search_by_query con término que no coincide devuelve colección vacía" do
    User.create!(name: "Eduardo", email: "edu@test.com", password: "password123")
    resultados = User.search_by_query("zzz_no_existe_zzz")
    assert_empty resultados
  end

  test "search_by_query es case-insensitive" do
    user = User.create!(name: "Fernanda", email: "fer@test.com", password: "password123")
    resultados = User.search_by_query("FERNANDA")
    assert_includes resultados, user
  end

  test "search_by_query devuelve múltiples resultados" do
    u1 = User.create!(name: "Gabriel Test", email: "gabriel@test.com", password: "password123")
    u2 = User.create!(name: "Gabriela Test", email: "gabriela@test.com", password: "password123")
    resultados = User.search_by_query("gabriel")
    assert_includes resultados, u1
    assert_includes resultados, u2
  end

  # asociaciones

  test "usuario tiene muchas compras" do
    user = User.create!(name: "Héctor", email: "hector@test.com", password: "password123")
    compra = Compra.create!(
      user: user, email: user.email,
      numero_orden: "FA-USR-TEST-001", cantidad: 1,
      precio_total: 50_000, estado: "pendiente"
    )
    assert_includes user.compras, compra
  end

  # Devise validations 

  test "email debe ser único" do
    User.create!(name: "Isabel", email: "unico@test.com", password: "password123")
    dup = User.new(name: "Otro", email: "unico@test.com", password: "password123")
    assert_not dup.valid?
    assert dup.errors[:email].any?
  end
end
