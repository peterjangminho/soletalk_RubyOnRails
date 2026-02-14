class VoiceChatData < ApplicationRecord
  self.table_name = "voice_chat_data"

  belongs_to :session
end
