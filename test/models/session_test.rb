require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "P8-T1 belongs_to user and validates status" do
    session = Session.new(status: "active")

    assert_not session.valid?
    assert_includes session.errors[:user], "must exist"

    user = User.create!(google_sub: "g-session", email: "s@example.com")
    valid_session = Session.new(user: user, status: "active")

    assert valid_session.valid?
  end
end
