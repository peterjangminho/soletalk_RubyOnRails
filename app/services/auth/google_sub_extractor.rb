module Auth
  class GoogleSubExtractor
    def self.call(auth_hash)
      auth_hash["uid"] || auth_hash[:uid]
    end
  end
end
