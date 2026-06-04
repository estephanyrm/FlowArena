require "application_system_test_case"

class AutenticacionTest < ApplicationSystemTestCase
  def teardown
    User.where(email: ["nuevo@test.com", "login@test.com", "duplicado@test.com"]).destroy_all
    super
  end

  test "ST-01: registro exitoso de nuevo usuario" do
    visit new_user_registration_path

    fill_in "Nombre",    with: "Estephany Ruales"
    fill_in "E-Mail",    with: "nuevo_#{SecureRandom.hex(4)}@test.com"  # ← único
    fill_in "Contraseña", with: "password123"
    find("input[name='habeas_data']", visible: :all).check
    click_button "Registrarse"

    assert_text "creada correctamente"
    assert_current_path root_path
  end

  test "ST-02: inicio de sesión válido" do
    User.create!(
      name:     "Estephany",
      email:    "login@test.com",
      password: "password123"
    )

    visit new_user_session_path
    fill_in "E-Mail",     with: "login@test.com"
    fill_in "Contraseña", with: "password123"
    find("input[name='habeas_data']").check  
    click_button "Ingresar"

    assert_text "Sesión iniciada correctamente."
    assert_current_path root_path
  end

  test "ST-03: registro con email duplicado muestra error" do
    User.create!(
      name: "Ya existe", email: "duplicado@test.com", password: "password123"
    )

    visit new_user_registration_path
    fill_in "Nombre",     with: "Cualquier Nombre"       
    fill_in "E-Mail",     with: "duplicado@test.com"
    fill_in "Contraseña", with: "password123"
    find("input[name='habeas_data']").check
    click_button "Registrarse"

    assert_text "ya está en uso"
  end

  test "ST-04: login con credenciales inválidas" do
    visit new_user_session_path
    fill_in "E-Mail",     with: "noexiste@test.com"
    fill_in "Contraseña", with: "mal_password"
    find("input[name='habeas_data']").check   
    click_button "Ingresar"

    assert_current_path new_user_session_path
    assert_text "o contraseña inválidos"
  end

end