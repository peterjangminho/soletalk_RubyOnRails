module Ops
  class PreflightCheck
    REQUIRED_ARTIFACTS = [
      "Dockerfile",
      ".github/workflows/ci.yml",
      "railway.json"
    ].freeze

    def initialize(env: ENV.to_h, root_path: Rails.root.to_s)
      @env = env
      @root_path = root_path
    end

    def call
      env_result = Ops::EnvValidator.new(env: @env).validate
      artifacts = REQUIRED_ARTIFACTS.index_with do |relative_path|
        File.exist?(File.join(@root_path, relative_path))
      end

      {
        ok: env_result[:ok] && artifacts.values.all?,
        timestamp: Time.current.iso8601,
        env: env_result,
        artifacts: artifacts
      }
    end
  end
end
