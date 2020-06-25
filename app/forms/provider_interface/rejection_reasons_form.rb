module ProviderInterface
  class RejectionReasonsForm
    include ActiveModel::Model

    FIELDS = %i[
      candidate_behaviour
      candidate_did_not_reply_to_interview_offer
      candidate_did_not_attend_interview
      candidate_behaviour_other
      candidate_behaviour_other_details
      candidate_behaviour_other_advice

      quality_of_application
      quality_of_personal_statement
      quality_of_subject_knowledge
      quality_other
      quality_other_details
      quality_other_advice

      qualifications
      qualifications_no_maths
      qualifications_no_english
      qualifications_no_science
      qualifications_no_degree
      qualifications_invalid_degree
      qualifications_other
      qualifications_other_details

      performance_at_interview
      performance_improvement_advice

      course_is_full

      alternative_course_offered

      honesty_and_professionalism
      false_or_inaccurate_information
      plagiarism
      references_did_not_support_application
      honesty_and_professionalism_other
      honesty_and_professionalism_other_details

      safeguarding
      safeguarding_unsuitable_disclosed
      safeguarding_unsuitable_vetting
      safeguarding_other
      safeguarding_other_details

      alternative_reason_for_rejection

      other_advice
      other_advice_details

      future_applications
    ].freeze

    attr_accessor(*FIELDS)
    attr_accessor :step_1_complete

    validate :candidate_behaviour_valid

    def candidate_behaviour_valid
      return if candidate_behaviour == 'false'
      return if candidate_did_not_reply_to_interview_offer == 'true' || candidate_did_not_attend_interview == 'true'

      if candidate_behaviour_other == 'true'
        return if candidate_behaviour_other_details.present?
        return if candidate_behaviour_other_advice.present?

        errors.add(:candidate_behaviour_other, 'please give details')
      else
        errors.add(:candidate_behaviour, 'please select one')
      end
    end

    def validate_safeguarding
      return if safeguarding
      return if safeguarding_unsuitable_disclosed || safeguarding_unsuitable_vetting

      if safeguarding_other
        return if safeguarding_other_details.present?

        errors.add(:safeguarding_other, 'please give details')
      else
        errors.add(:safeguarding, 'please select one')
      end
    end

    def additional_questions?
      step_1_complete && !honesty_and_professionalism && !safeguarding
    end
  end
end
