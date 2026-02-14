require "json"

namespace :ops do
  desc "Run deployment preflight checks"
  task preflight: :environment do
    result = Ops::PreflightCheck.new.call
    puts JSON.pretty_generate(result)
    exit(1) unless result[:ok]
  end
end
