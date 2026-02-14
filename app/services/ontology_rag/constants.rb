module OntologyRag
  module Constants
    SOURCE_APP = "soletalk-rails".freeze
    APP_SOURCE = "incar_companion".freeze

    ENDPOINTS = {
      identify_user: "/engine/users/identify",
      get_profile: "/engine/prompts/%{google_sub}",
      get_cached_profile: "/incar/profile/%{google_sub}",
      batch_save_events: "/incar/events/batch",
      save_conversation: "/incar/conversations/%{session_id}/save"
    }.freeze

    TIMEOUTS = {
      open: 3,
      read: 8,
      retries: 2
    }.freeze
  end
end
