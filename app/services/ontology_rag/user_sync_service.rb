module OntologyRag
  class UserSyncService
    def initialize(client: Client.new)
      @client = client
    end

    def call(google_sub:)
      response = @client.identify_user(google_sub: google_sub)

      if response["success"] == false
        return {
          success: false,
          error: response["error"],
          message: response["message"]
        }
      end

      {
        success: true,
        user_id: response["id"],
        google_sub: response["google_sub"],
        is_new: response["is_new"]
      }
    end
  end
end
