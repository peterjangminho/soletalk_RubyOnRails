require "test_helper"

module Ops
  class PreflightCheckTest < ActiveSupport::TestCase
    test "P48-T1 validates env and deployment artifacts" do
      check = Ops::PreflightCheck.new(
        env: {
          "ONTOLOGY_RAG_BASE_URL" => "https://example.test",
          "ONTOLOGY_RAG_API_KEY" => "key",
          "GOOGLE_CLIENT_ID" => "id",
          "GOOGLE_CLIENT_SECRET" => "secret",
          "SECRET_KEY_BASE" => "base"
        },
        root_path: Rails.root.to_s
      )

      result = check.call

      assert_equal true, result[:ok]
      assert_equal true, result[:artifacts]["Dockerfile"]
      assert_equal true, result[:artifacts][".github/workflows/ci.yml"]
      assert_equal true, result[:artifacts]["railway.json"]
    end

    test "P48-T3 returns non-ok when critical files are missing" do
      check = Ops::PreflightCheck.new(
        env: {
          "ONTOLOGY_RAG_BASE_URL" => "https://example.test",
          "ONTOLOGY_RAG_API_KEY" => "key",
          "GOOGLE_CLIENT_ID" => "id",
          "GOOGLE_CLIENT_SECRET" => "secret",
          "SECRET_KEY_BASE" => "base"
        },
        root_path: "/tmp/not-existing-project"
      )

      result = check.call

      assert_equal false, result[:ok]
      assert_equal false, result[:artifacts]["Dockerfile"]
    end

    test "P48-T2 exposes machine-readable summary hash" do
      check = Ops::PreflightCheck.new(env: {}, root_path: "/tmp/none")
      result = check.call

      assert result.key?(:ok)
      assert result.key?(:timestamp)
      assert result.key?(:env)
      assert result.key?(:artifacts)
    end
  end
end
