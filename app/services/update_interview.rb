class UpdateInterview
  attr_reader :auth, :interview, :provider, :date_and_time, :location, :additional_details

  def initialize(
    actor:,
    interview:,
    provider:,
    date_and_time:,
    location:,
    additional_details:
  )
    @auth = ProviderAuthorisation.new(actor: actor)
    @interview = interview
    @provider = provider
    @date_and_time = date_and_time
    @location = location
    @additional_details = additional_details
  end

  def save!
    auth.assert_can_make_decisions!(
      application_choice: interview.application_choice,
      course_option_id: interview.application_choice.offered_option.id,
    )

    interview.update!(
      provider: provider,
      date_and_time: date_and_time,
      location: location,
      additional_details: additional_details,
    )

    CandidateMailer.interview_updated(interview.application_choice, interview).deliver_later
  end
end
