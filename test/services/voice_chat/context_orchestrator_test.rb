require "test_helper"

class VoiceChatContextOrchestratorTest < ActiveSupport::TestCase
  class FakeOntologyClient
    cattr_accessor :calls

    self.calls = []

    def get_cached_profile(google_sub:)
      self.class.calls << { type: :profile, google_sub: google_sub }
      { google_sub: google_sub, profile: { name: "FromProfile" } }
    end

    def query(question:, google_sub: nil, limit: 5, container_id: nil)
      self.class.calls << { type: :query, question: question, google_sub: google_sub, limit: limit }
      {
        answer: "answer for #{question}",
        context: "context",
        sources: [ { id: "s1" } ],
        query: question
      }
    end
  end

  test "P16-T1 builds 5-layer context payload" do
    orchestrator = VoiceChat::ContextOrchestrator.new(cache_store: ActiveSupport::Cache::MemoryStore.new)

    payload = orchestrator.build(
      profile: { name: "Kim" },
      past_memory: [ { id: 1 } ],
      current_session: { phase: "free_speech" },
      additional_info: { weather: "rain" },
      ai_persona: { style: "calm" }
    )

    assert_equal %i[profile past_memory current_session additional_info ai_persona].sort, payload.keys.sort
    assert_equal "Kim", payload[:profile][:name]
    assert_equal "free_speech", payload[:current_session][:phase]
  end

  test "P19-T1 caches profile/past_memory/additional_info/ai_persona with layer-specific TTL" do
    cache_store = ActiveSupport::Cache::MemoryStore.new
    orchestrator = VoiceChat::ContextOrchestrator.new(cache_store: cache_store)

    first = orchestrator.build(
      google_sub: "g-1",
      session_id: "s-1",
      profile: { name: "Kim" },
      past_memory: [ { id: 1 } ],
      current_session: { phase: "opener" },
      additional_info: { weather: "rain" },
      ai_persona: { style: "calm" }
    )

    second = orchestrator.build(
      google_sub: "g-1",
      session_id: "s-1",
      profile: { name: "Lee" },
      past_memory: [ { id: 2 } ],
      current_session: { phase: "emotion_expansion" },
      additional_info: { weather: "sunny" },
      ai_persona: { style: "energetic" }
    )

    assert_equal "Kim", first[:profile][:name]
    assert_equal "Kim", second[:profile][:name]
    assert_equal [ { id: 1 } ], second[:past_memory]
    assert_equal({ weather: "rain" }, second[:additional_info])
    assert_equal({ style: "calm" }, second[:ai_persona])
  end

  test "P19-T2 does not cache current_session layer" do
    orchestrator = VoiceChat::ContextOrchestrator.new(cache_store: ActiveSupport::Cache::MemoryStore.new)

    first = orchestrator.build(
      google_sub: "g-2",
      session_id: "s-2",
      profile: { name: "Kim" },
      past_memory: [ { id: 1 } ],
      current_session: { phase: "opener" },
      additional_info: { weather: "rain" },
      ai_persona: { style: "calm" }
    )

    second = orchestrator.build(
      google_sub: "g-2",
      session_id: "s-2",
      profile: { name: "Kim" },
      past_memory: [ { id: 1 } ],
      current_session: { phase: "calm" },
      additional_info: { weather: "rain" },
      ai_persona: { style: "calm" }
    )

    assert_equal "opener", first[:current_session][:phase]
    assert_equal "calm", second[:current_session][:phase]
  end

  test "P19-T3 reuses cache key scope by google_sub/session_id" do
    orchestrator = VoiceChat::ContextOrchestrator.new(cache_store: ActiveSupport::Cache::MemoryStore.new)

    first_scope = orchestrator.build(
      google_sub: "g-scope-1",
      session_id: "session-1",
      profile: { name: "Scope One" },
      past_memory: [ { id: 1 } ],
      current_session: { phase: "opener" },
      additional_info: { weather: "rain" },
      ai_persona: { style: "calm" }
    )

    second_scope = orchestrator.build(
      google_sub: "g-scope-2",
      session_id: "session-2",
      profile: { name: "Scope Two" },
      past_memory: [ { id: 2 } ],
      current_session: { phase: "opener" },
      additional_info: { weather: "sunny" },
      ai_persona: { style: "calm" }
    )

    assert_equal "Scope One", first_scope[:profile][:name]
    assert_equal "Scope Two", second_scope[:profile][:name]
    assert_equal [ { id: 1 } ], first_scope[:past_memory]
    assert_equal [ { id: 2 } ], second_scope[:past_memory]
  end

  test "P41-T1/P41-T2/P41-T3 builds L2/L4/profile from OntologyRag sources" do
    cache_store = ActiveSupport::Cache::MemoryStore.new
    FakeOntologyClient.calls = []
    orchestrator = VoiceChat::ContextOrchestrator.new(
      cache_store: cache_store,
      ontology_client: FakeOntologyClient.new
    )

    payload = orchestrator.build_dynamic(
      google_sub: "g-dynamic",
      session_id: "s-dynamic",
      current_session: { phase: "free_speech" },
      ai_persona: { style: "calm" },
      additional_query: "news for decision"
    )

    assert_equal "FromProfile", payload[:profile][:name]
    assert_equal "answer for recent memory context", payload[:past_memory][:answer]
    assert_equal "answer for news for decision", payload[:additional_info][:answer]
    assert_equal "free_speech", payload[:current_session][:phase]
  end
end
