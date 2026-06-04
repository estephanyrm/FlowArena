require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # ── after_sign_in_path_for ─────

  test "after_sign_in redirige admin al dashboard" do
    admin = Admin.create!(email: "admin@test.com", password: "admin123456")
    post admin_session_path, params: {
      admin: { email: "admin@test.com", password: "admin123456" }
    }
    assert_redirected_to admin_dashboard_path
  end

  test "after_sign_in redirige usuario normal a root" do
    user = User.create!(name: "Ana", email: "ana@test.com", password: "password123")
    post user_session_path, params: {
      user: { email: "ana@test.com", password: "password123" }
    }
    assert_redirected_to root_path
  end

  # ── configure_permitted_parameters ───────────────────────────────────────

  test "registro de usuario permite el campo name" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          name: "Nuevo Usuario",
          email: "nuevo@test.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    creado = User.find_by(email: "nuevo@test.com")
    assert_not_nil creado
    assert_equal "Nuevo Usuario", creado.name
  end
end
