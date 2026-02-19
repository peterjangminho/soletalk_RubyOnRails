require "test_helper"

class DevSignInFlowTest < ActionDispatch::IntegrationTest
  test "P73-T1 POST /dev/sign_in creates dev user session in test env" do
    assert_nil User.find_by(google_sub: "dev-mobile-user")

    post "/dev/sign_in"

    assert_redirected_to "/"
    follow_redirect!
    assert_response :ok
    assert_includes response.body, "main-screen"
    assert_not_nil User.find_by(google_sub: "dev-mobile-user")
  end

  test "P73-T2 DELETE /dev/sign_out clears session and returns guest home" do
    post "/dev/sign_in"
    delete "/dev/sign_out"

    assert_redirected_to "/"
    follow_redirect!
    assert_response :ok
    assert_includes response.body, "Sign In"
    assert_not_includes response.body, "main-screen"
  end
end
