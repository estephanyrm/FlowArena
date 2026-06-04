require "test_helper"

class ProfileTest < ActiveSupport::TestCase

  test "profile pertenece a un usuario" do
    user = User.create!(name: "Julián", email: "julian@test.com", password: "password123")
    profile = Profile.create!(user: user)
    assert_equal user, profile.user
  end

  test "profile no es válido sin usuario" do
    profile = Profile.new
    assert_not profile.valid?
    assert profile.errors[:user].any?
  end

  test "se puede acceder al usuario desde el profile" do
    user = User.create!(name: "Leonardo", email: "leo@test.com", password: "password123")
    profile = Profile.create!(user: user)
    assert_equal "Leonardo", profile.user.name
  end

  test "dos profiles pueden pertenecer a usuarios distintos" do
    u1 = User.create!(name: "Mario", email: "mario@test.com", password: "password123")
    u2 = User.create!(name: "Nora", email: "nora@test.com", password: "password123")
    p1 = Profile.create!(user: u1)
    p2 = Profile.create!(user: u2)
    assert_not_equal p1.user_id, p2.user_id
  end
end