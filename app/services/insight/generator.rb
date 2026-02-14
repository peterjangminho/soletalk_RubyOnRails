class Insight::Generator
  def call(q1_answer:, q2_answer:, q3_answer:, q4_answer:, engc_profile: {})
    Insight.create!(
      situation: q1_answer,
      decision: q2_answer,
      action_guide: q3_answer,
      data_info: q4_answer,
      engc_profile: engc_profile
    )
  end
end
