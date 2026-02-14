require "omniauth"

OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
  provider: "google_oauth2",
  uid: "default-google-sub",
  info: {
    email: "default@example.com",
    name: "Default User"
  }
)
