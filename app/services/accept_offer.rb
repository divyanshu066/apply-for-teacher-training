class AcceptOffer
  def initialize(application_choice:)
    @application_choice = application_choice
  end

  def save!
    ActiveRecord::Base.transaction do
      ApplicationStateChange.new(@application_choice).accept!
      @application_choice.update!(accepted_at: Time.zone.now)

      StateChangeNotifier.disable_notifications do
        other_application_choices_with_offers.each do |application_choice|
          DeclineOffer.new(application_choice: application_choice).save!
        end

        application_choices_awaiting_provider_decision.each do |application_choice|
          WithdrawApplication.new(application_choice: application_choice).save!
        end
      end
    end

    NotificationsList.for(@application_choice, include_ratifying_provider: true).each do |provider_user|
      ProviderMailer.offer_accepted(provider_user, @application_choice).deliver_later
    end

    CandidateMailer.offer_accepted(@application_choice).deliver_later
  end

private

  def other_application_choices_with_offers
    @application_choice
      .self_and_siblings
      .offer
      .where.not(id: @application_choice.id)
  end

  def application_choices_awaiting_provider_decision
    @application_choice
      .self_and_siblings
      .awaiting_provider_decision
  end
end
