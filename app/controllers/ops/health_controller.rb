module Ops
  class HealthController < ApplicationController
    skip_forgery_protection

    def show
      render json: {
        ok: true,
        service: "soletalk-rails",
        version: app_version,
        timestamp: Time.current.iso8601,
        database: database_status
      }
    end

    private

    def database_status
      ActiveRecord::Base.connection.execute("SELECT 1")
      "ok"
    rescue StandardError # health check: intentionally returns "error" status without raising
      "error"
    end

    def app_version
      ENV["APP_VERSION"].presence || "dev"
    end
  end
end
