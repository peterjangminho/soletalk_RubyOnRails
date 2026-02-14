VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("test/cassettes")
  config.hook_into :webmock
  config.ignore_localhost = true
  config.allow_http_connections_when_no_cassette = false
  config.default_cassette_options = {
    record: :none,
    match_requests_on: %i[method uri body]
  }
end
