require "test_helper"

class OntologyRagModelsTest < ActiveSupport::TestCase
  test "P6-T2 ENGC profile keeps singular keys only" do
    profile = OntologyRag::Models::EngcProfile.new(
      emotion: [ "anxiety" ],
      need: [ "stability" ],
      goal: [ "promotion" ],
      constraint: [ "time" ],
      ignored: [ "x" ]
    )

    assert_equal %i[emotion need goal constraint], profile.to_h.keys
    assert_equal [ "anxiety" ], profile.to_h[:emotion]
  end

  test "P6-T3 query response normalizes nil sources" do
    response = OntologyRag::Models::QueryResponse.from_api(
      "answer" => "A",
      "context" => "C",
      "sources" => nil,
      "query" => "Q"
    )

    assert_equal "A", response.answer
    assert_equal "C", response.context
    assert_equal [], response.sources
    assert_equal "Q", response.query
  end
end
