module Subscription
  class FeatureGate
    FREE_DAILY_SESSION_LIMIT = 2
    FREE_HISTORY_DAYS = 7

    def daily_session_remaining(user, reference_time: Time.current)
      return Float::INFINITY if user.premium?

      today_count = user.sessions.where(created_at: reference_time.all_day).count
      [ FREE_DAILY_SESSION_LIMIT - today_count, 0 ].max
    end

    def history_accessible?(user, session_record, reference_time: Time.current)
      return true if user.premium?

      session_record.created_at > (reference_time - FREE_HISTORY_DAYS.days)
    end
  end
end
