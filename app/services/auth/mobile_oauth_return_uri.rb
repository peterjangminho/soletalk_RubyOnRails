module Auth
  class MobileOauthReturnUri
    ALLOWLIST = [ "soletalk://auth" ].freeze

    class << self
      def normalize(value)
        uri = value.to_s
        return nil if uri.blank?

        ALLOWLIST.include?(uri) ? uri : nil
      end
    end
  end
end
