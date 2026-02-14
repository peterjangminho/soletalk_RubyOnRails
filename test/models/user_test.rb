require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "P7-T1 validates google_sub presence" do
    user = User.new(email: "a@example.com")

    assert_not user.valid?
    assert_includes user.errors[:google_sub], "can't be blank"
  end

  test "P7-T1 validates google_sub uniqueness" do
    User.create!(google_sub: "g-1", email: "a@example.com")
    duplicate = User.new(google_sub: "g-1", email: "b@example.com")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:google_sub], "has already been taken"
  end
end
