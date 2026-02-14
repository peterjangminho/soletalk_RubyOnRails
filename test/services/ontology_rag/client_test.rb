require "test_helper"

class OntologyRagClientTest < ActiveSupport::TestCase
  parallelize(workers: 1)

  setup do
    @previous_base_url = ENV["ONTOLOGY_RAG_BASE_URL"]
    @previous_api_key = ENV["ONTOLOGY_RAG_API_KEY"]
    ENV["ONTOLOGY_RAG_BASE_URL"] = "https://example.test"
    ENV["ONTOLOGY_RAG_API_KEY"] = "sk_test_123"
  end

  teardown do
    ENV["ONTOLOGY_RAG_BASE_URL"] = @previous_base_url
    ENV["ONTOLOGY_RAG_API_KEY"] = @previous_api_key
  end

  test "P1-T1 initializes required headers" do
    client = OntologyRag::Client.new

    headers = client.default_headers

    assert_equal "sk_test_123", headers["X-API-Key"]
    assert_equal "soletalk-rails", headers["X-Source-App"]
    assert headers["X-Request-ID"].start_with?("soletalk-")
  end

  test "P1-T2 raises configuration error when required env vars are missing" do
    ENV.delete("ONTOLOGY_RAG_BASE_URL")

    error = assert_raises(OntologyRag::Client::ConfigurationError) do
      OntologyRag::Client.new
    end

    assert_includes error.message, "ONTOLOGY_RAG_BASE_URL"
  end

  test "P1-T3 identify_user posts to /engine/users/identify with google_sub" do
    capture = {}
    adapter = lambda do |request|
      capture[:request] = request
      { "id" => "u-1", "google_sub" => request[:body][:google_sub], "is_new" => true }
    end

    client = OntologyRag::Client.new(http_adapter: adapter)
    response = client.identify_user(google_sub: "google-sub-123")

    assert_equal "/engine/users/identify", capture.dig(:request, :path)
    assert_equal :post, capture.dig(:request, :method)
    assert_equal "google-sub-123", capture.dig(:request, :body, :google_sub)
    assert_equal "incar_companion", capture.dig(:request, :body, :app_source)
    assert_equal "google-sub-123", response["google_sub"]
  end

  test "P1-T4 query posts to /engine/query and normalizes response" do
    capture = {}
    adapter = lambda do |request|
      capture[:request] = request
      {
        "answer" => "A",
        "context" => "C",
        "sources" => [ { "id" => "s1", "score" => 0.8 } ],
        "query" => request[:body][:question]
      }
    end

    client = OntologyRag::Client.new(http_adapter: adapter)
    response = client.query(question: "What matters?", google_sub: "g-sub")

    assert_equal "/engine/query", capture.dig(:request, :path)
    assert_equal :post, capture.dig(:request, :method)
    assert_equal "What matters?", capture.dig(:request, :body, :question)
    assert_equal "g-sub", capture.dig(:request, :body, :google_sub)

    assert_equal "A", response[:answer]
    assert_equal "C", response[:context]
    assert_equal [ { "id" => "s1", "score" => 0.8 } ], response[:sources]
    assert_equal "What matters?", response[:query]
  end

  test "P39-T1/P39-T3 query caches identical requests with google_sub+question key" do
    calls = 0
    adapter = lambda do |_request|
      calls += 1
      {
        "answer" => "A#{calls}",
        "context" => "C",
        "sources" => [],
        "query" => "Q"
      }
    end
    cache_store = ActiveSupport::Cache::MemoryStore.new
    client = OntologyRag::Client.new(http_adapter: adapter, cache_store: cache_store, query_cache_ttl: 60)

    first = client.query(question: "same question", google_sub: "g-cache-1")
    second = client.query(question: "same question", google_sub: "g-cache-1")
    third = client.query(question: "same question", google_sub: "g-cache-2")

    assert_equal "A1", first[:answer]
    assert_equal "A1", second[:answer]
    assert_equal "A2", third[:answer]
    assert_equal 2, calls
  end

  test "P39-T2 cached query entry expires after configured ttl" do
    calls = 0
    adapter = lambda do |_request|
      calls += 1
      {
        "answer" => "A#{calls}",
        "context" => "C",
        "sources" => [],
        "query" => "Q"
      }
    end
    cache_store = ActiveSupport::Cache::MemoryStore.new
    client = OntologyRag::Client.new(http_adapter: adapter, cache_store: cache_store, query_cache_ttl: 0.001)

    first = client.query(question: "ttl question", google_sub: "g-ttl")
    sleep 0.01
    second = client.query(question: "ttl question", google_sub: "g-ttl")

    assert_equal "A1", first[:answer]
    assert_equal "A2", second[:answer]
    assert_equal 2, calls
  end

  test "P1-T5 handles timeout retry and fallback" do
    attempts = 0
    flaky_adapter = lambda do |_request|
      attempts += 1
      raise Timeout::Error, "temporary timeout" if attempts < 3

      { "answer" => "Recovered", "context" => nil, "sources" => [], "query" => "q" }
    end

    retrying_client = OntologyRag::Client.new(http_adapter: flaky_adapter, retry_attempts: 2)
    recovered = retrying_client.query(question: "q")

    assert_equal 3, attempts
    assert_equal "Recovered", recovered[:answer]

    always_timeout = lambda do |_request|
      raise Timeout::Error, "still timing out"
    end

    fallback_client = OntologyRag::Client.new(http_adapter: always_timeout, retry_attempts: 1)
    fallback = fallback_client.identify_user(google_sub: "g")

    assert_equal false, fallback["success"]
    assert_equal "Timeout::Error", fallback["error"]
    assert_equal "/engine/users/identify", fallback["path"]
  end

  test "P2-T1 get_prompts requests /engine/prompts/{google_sub}" do
    capture = {}
    adapter = lambda do |request|
      capture[:request] = request
      { "google_sub" => "g-1", "needs" => { "items" => [] } }
    end

    client = OntologyRag::Client.new(http_adapter: adapter)
    response = client.get_prompts(google_sub: "g-1", limit: 25)

    assert_equal :get, capture.dig(:request, :method)
    assert_equal "/engine/prompts/g-1", capture.dig(:request, :path)
    assert_equal 25, capture.dig(:request, :params, :limit)
    assert_equal "g-1", response["google_sub"]
  end

  test "P37-T2 get_cached_profile requests /incar/profile/{google_sub}" do
    capture = {}
    adapter = lambda do |request|
      capture[:request] = request
      { "google_sub" => "g-cache", "profile" => { "goal" => "focus" } }
    end

    client = OntologyRag::Client.new(http_adapter: adapter)
    response = client.get_cached_profile(google_sub: "g-cache")

    assert_equal :get, capture.dig(:request, :method)
    assert_equal "/incar/profile/g-cache", capture.dig(:request, :path)
    assert_equal "g-cache", response[:google_sub]
    assert_equal({ "goal" => "focus" }, response[:profile])
  end

  test "P2-T2 record_events posts to /incar/events/batch" do
    capture = {}
    adapter = lambda do |request|
      capture[:request] = request
      { "success" => true, "processed" => request[:body][:events].size }
    end

    client = OntologyRag::Client.new(http_adapter: adapter)
    response = client.record_events(
      google_sub: "g-1",
      events: [ { event_type: "emotion", payload: { emotion: "anxiety" } } ]
    )

    assert_equal :post, capture.dig(:request, :method)
    assert_equal "/incar/events/batch", capture.dig(:request, :path)
    assert_equal "g-1", capture.dig(:request, :body, :google_sub)
    assert_equal 1, capture.dig(:request, :body, :events).size
    assert_equal true, response["success"]
  end

  test "P2-T3 save_conversation posts to /incar/conversations/{session_id}/save" do
    capture = {}
    adapter = lambda do |request|
      capture[:request] = request
      { "success" => true, "session_id" => "sess-1" }
    end

    client = OntologyRag::Client.new(http_adapter: adapter)
    response = client.save_conversation(
      session_id: "sess-1",
      google_sub: "g-1",
      conversation: [ { role: "user", text: "hello" } ],
      metadata: { phase: "free_speech" }
    )

    assert_equal :post, capture.dig(:request, :method)
    assert_equal "/incar/conversations/sess-1/save", capture.dig(:request, :path)
    assert_equal "g-1", capture.dig(:request, :body, :google_sub)
    assert_equal "hello", capture.dig(:request, :body, :conversation, 0, :text)
    assert_equal "free_speech", capture.dig(:request, :body, :metadata, :phase)
    assert_equal true, response["success"]
  end
end
