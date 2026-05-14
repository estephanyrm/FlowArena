require "test_helper"

class AdminTest < ActiveSupport::TestCase
  test "no debería guardar un admin sin correo" do
    admin = Admin.new(password: "admin123")
    assert_not admin.save, "Guardó el administrador sin correo"
  end

  test "la contraseña del admin debería estar cifrada" do
    admin = Admin.create!(email: "admin@flowarena.com", password: "admin_password")
    assert_not_equal "admin_password", admin.encrypted_password, "La contraseña del admin no se guardó cifrada"
  end

  test "no debería permitir correos duplicados en admins" do
    Admin.create!(email: "boss@flowarena.com", password: "password123")
    admin2 = Admin.new(email: "boss@flowarena.com", password: "password456")
    assert_not admin2.save, "Permitió registrar un correo de admin ya existente"
  end
end
