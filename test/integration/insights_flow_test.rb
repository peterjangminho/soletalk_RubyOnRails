require "test_helper"

class InsightsFlowTest < ActionDispatch::IntegrationTest
  def sign_in(google_sub:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: google_sub,
      info: {
        email: "#{google_sub}@example.com",
        name: "Insight User"
      }
    )

    get "/auth/google_oauth2/callback"
    follow_redirect!
    User.find_by!(google_sub: google_sub).update!(
      subscription_status: "premium",
      subscription_tier: "premium",
      subscription_expires_at: 2.days.from_now
    )
  end

  test "P18-T1 GET /insights returns ordered insight list" do
    older = Insight.create!(
      situation: "older situation",
      decision: "older decision",
      action_guide: "older action",
      data_info: "older data",
      created_at: 2.days.ago
    )
    newer = Insight.create!(
      situation: "newer situation",
      decision: "newer decision",
      action_guide: "newer action",
      data_info: "newer data",
      created_at: 1.day.ago
    )

    sign_in(google_sub: "insight-index-user")
    get "/insights"

    assert_response :ok
    assert_operator response.body.index(newer.situation), :<, response.body.index(older.situation)
  end

  test "P25-T1 GET /insights renders card-based timeline list" do
    Insight.create!(
      situation: "timeline situation",
      decision: "timeline decision",
      action_guide: "timeline action",
      data_info: "timeline data"
    )

    sign_in(google_sub: "insight-timeline-user")
    get "/insights"

    assert_response :ok
    assert_includes response.body, "insight-timeline"
    assert_includes response.body, "insight-card"
  end

  test "P18-T2 GET /insights/:id renders selected insight" do
    insight = Insight.create!(
      situation: "selected situation",
      decision: "selected decision",
      action_guide: "selected action",
      data_info: "selected data"
    )

    sign_in(google_sub: "insight-show-user")
    get "/insights/#{insight.id}"

    assert_response :ok
    assert_includes response.body, insight.situation
    assert_includes response.body, insight.decision
    assert_includes response.body, insight.action_guide
    assert_includes response.body, insight.data_info
  end

  test "P25-T2 GET /insights/:id renders Q1~Q4 detail cards" do
    insight = Insight.create!(
      situation: "q1 detail",
      decision: "q2 detail",
      action_guide: "q3 detail",
      data_info: "q4 detail"
    )

    sign_in(google_sub: "insight-q-user")
    get "/insights/#{insight.id}"

    assert_response :ok
    assert_includes response.body, "Q1. WHY"
    assert_includes response.body, "Q2. DECISION"
    assert_includes response.body, "Q3. IMPACT"
    assert_includes response.body, "Q4. DATA"
    assert_includes response.body, "insight-detail-card"
  end
end
