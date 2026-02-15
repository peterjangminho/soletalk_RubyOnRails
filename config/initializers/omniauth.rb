OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch("GOOGLE_CLIENT_ID", "test-google-client-id"),
           ENV.fetch("GOOGLE_CLIENT_SECRET", "test-google-client-secret"),
           {
             name: "google_oauth2",
             prompt: "select_account",
             access_type: "offline"
           }
end
