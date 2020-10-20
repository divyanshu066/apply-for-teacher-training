class GenerateTestApplications
  include Sidekiq::Worker

  def perform
    raise 'You cannot generate test data in production' if HostingEnvironment.production?

    create recruitment_cycle_year: 2020, states: %i[rejected rejected]
    create recruitment_cycle_year: 2020, states: %i[offer_withdrawn]
    create recruitment_cycle_year: 2020, states: %i[offer_deferred]
    create recruitment_cycle_year: 2020, states: %i[offer_deferred]
    create recruitment_cycle_year: 2020, states: %i[declined]
    create recruitment_cycle_year: 2020, states: %i[accepted]
    create recruitment_cycle_year: 2020, states: %i[recruited]
    create recruitment_cycle_year: 2020, states: %i[conditions_not_met]
    create recruitment_cycle_year: 2020, states: %i[withdrawn]
    create recruitment_cycle_year: 2020, states: %i[application_not_sent]

    create recruitment_cycle_year: 2021, states: %i[unsubmitted]
    create recruitment_cycle_year: 2021, states: %i[unsubmitted], course_full: true
    create recruitment_cycle_year: 2021, states: %i[awaiting_provider_decision awaiting_provider_decision awaiting_provider_decision]
    create recruitment_cycle_year: 2021, states: %i[awaiting_provider_decision awaiting_provider_decision awaiting_provider_decision]
    create recruitment_cycle_year: 2021, states: %i[awaiting_provider_decision awaiting_provider_decision awaiting_provider_decision]
    create recruitment_cycle_year: 2021, states: %i[awaiting_provider_decision], apply_again: true
    create recruitment_cycle_year: 2021, states: %i[offer offer]
    create recruitment_cycle_year: 2021, states: %i[offer rejected]
    create recruitment_cycle_year: 2021, states: %i[rejected rejected]
    create recruitment_cycle_year: 2021, states: %i[offer_withdrawn]
    create recruitment_cycle_year: 2021, states: %i[offer_deferred]
    create recruitment_cycle_year: 2021, states: %i[offer_deferred]
    create recruitment_cycle_year: 2021, states: %i[declined]
    create recruitment_cycle_year: 2021, states: %i[accepted]
    create recruitment_cycle_year: 2021, states: %i[accepted_no_conditions]
    create recruitment_cycle_year: 2021, states: %i[recruited]
    create recruitment_cycle_year: 2021, states: %i[conditions_not_met]
    create recruitment_cycle_year: 2021, states: %i[withdrawn]

    without_slack_message_sending do
      RejectApplicationsByDefault.new.call
    end
  end

private

  def create(recruitment_cycle_year: nil, states:, apply_again: false, course_full: false)
    TestApplications.new.create_application(
      states: states,
      recruitment_cycle_year: recruitment_cycle_year,
      courses_to_apply_to: recruitment_cycle_year == 2020 ? courses_to_apply_to_in_2020 : courses_to_apply_to_in_2021,
      apply_again: apply_again,
      course_full: course_full,
    )
  end

  def courses_to_apply_to_in_2020
    if dev_support_user
      dev_support_user.providers.flat_map do |provider|
        provider.courses.where(open_on_apply: true, recruitment_cycle_year: 2020)
      end
    else
      Course.where(open_on_apply: true, recruitment_cycle_year: 2020)
    end
  end

  def courses_to_apply_to_in_2021
    if dev_support_user
      dev_support_user.providers.flat_map do |provider|
        provider.courses.where(open_on_apply: true, exposed_in_find: true, recruitment_cycle_year: 2021)
      end
    else
      Course.where(open_on_apply: true, exposed_in_find: true, recruitment_cycle_year: 2021)
    end
  end

  def dev_support_user
    @dev_support_user ||= ProviderUser.find_by_dfe_sign_in_uid('dev-support')
  end

  def without_slack_message_sending
    RequestStore.store[:disable_slack_messages] = true
    yield
    RequestStore.store[:disable_slack_messages] = false
  end
end
