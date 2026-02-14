require "test_helper"

module Ops
  class EnvValidatorTest < ActiveSupport::TestCase
    test "P45-T2 reports missing required production env vars" do
      validator = Ops::EnvValidator.new(
        env: {
          "ONTOLOGY_RAG_BASE_URL" => "https://example.test",
          "ONTOLOGY_RAG_API_KEY" => nil,
          "GOOGLE_CLIENT_ID" => nil,
          "GOOGLE_CLIENT_SECRET" => "secret",
          "SECRET_KEY_BASE" => nil
        }
      )

      result = validator.validate

      assert_equal false, result[:ok]
      assert_includes result[:missing], "ONTOLOGY_RAG_API_KEY"
      assert_includes result[:missing], "GOOGLE_CLIENT_ID"
      assert_includes result[:missing], "SECRET_KEY_BASE"
    end
  end
end
