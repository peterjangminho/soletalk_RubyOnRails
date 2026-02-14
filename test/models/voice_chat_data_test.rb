require "test_helper"

class VoiceChatDataTest < ActiveSupport::TestCase
  test "P8-T3 has defaults and belongs_to session" do
    user = User.create!(google_sub: "g-vc", email: "v@example.com")
    session = Session.create!(user: user, status: "active")

    data = VoiceChatData.create!(session: session)

    assert_equal "opener", data.current_phase
    assert_equal [], data.phase_history
    assert_equal({}, data.metadata)
  end
end
