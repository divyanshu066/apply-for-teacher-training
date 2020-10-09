require 'rails_helper'

RSpec.feature 'Submitting an application' do
  include CandidateHelper

  scenario 'Candidate submits complete application' do
    given_i_am_signed_in
    and_the_decoupled_references_flag_is_on
    and_i_have_completed_my_application

    when_i_have_added_references
    and_i_submit_the_application
    then_i_get_an_error_about_my_references
    when_my_references_have_been_provided
    and_i_submit_the_application

    then_i_can_see_my_application_has_been_successfully_submitted
    and_its_in_the_right_state
    and_i_receive_an_email_about_my_submitted_application
    and_a_slack_notification_is_sent
    and_i_can_review_my_application
  end

  def given_i_am_signed_in
    create_and_sign_in_candidate
  end

  def and_the_decoupled_references_flag_is_on
    FeatureFlag.activate('decoupled_references')
  end

  def and_i_have_completed_my_application
    candidate_completes_application_form
  end

  def when_i_have_added_references
    create(:reference, :unsubmitted, application_form: current_candidate.current_application)
    create(:reference, :unsubmitted, application_form: current_candidate.current_application)
  end

  def and_i_submit_the_application
    visit candidate_interface_application_form_path
    click_link 'Check and submit your application'
    click_link 'Continue'
  end

  def then_i_get_an_error_about_my_references
    within '.govuk-error-summary' do
      expect(page).to have_content 'You need 2 references before you can submit your application'
    end
  end

  def when_my_references_have_been_provided
    application.application_references.each do |reference|
      SubmitReference.new(reference: reference).save!
    end
  end

  def then_i_can_see_my_application_has_been_successfully_submitted
    click_link 'Continue without completing questionnaire'
    choose 'No'
    click_button 'Send application'
  end

  def and_its_in_the_right_state
    expect(application.application_choices).to all(be_awaiting_provider_decision)
  end

  def and_i_receive_an_email_about_my_submitted_application
    open_email(current_candidate.email_address)

    expect(current_email.subject).to include 'You’ve submitted your teacher training application'
    expect(current_email.text).to include application.support_reference
  end

  def and_a_slack_notification_is_sent
    expect_slack_message_with_text "#{application.first_name}’s application is ready to be reviewed by #{provider.name}"
  end

  def and_i_can_review_my_application
    visit candidate_interface_application_form_path
    expect(page).to have_content 'Application dashboard'
    expect(page).to have_content 'Application submitted'
    expect(page).to have_link 'View application'
  end

private

  def application
    current_candidate.current_application
  end

  def provider
    application.application_choices.first.provider
  end
end
