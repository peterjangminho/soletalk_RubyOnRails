require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "P8-T2 belongs_to session and validates role enum" do
    user = User.create!(google_sub: "g-message", email: "m@example.com")
    session = Session.create!(user: user, status: "active")

    assert_raises(ArgumentError) do
      Message.new(session: session, role: "invalid", content: "hello")
    end

    valid_message = Message.new(session: session, role: "user", content: "hello")
    assert valid_message.valid?
  end
end
