require 'rails_helper'

RSpec.feature 'A candidate withdraws her application' do
  include CandidateHelper

  scenario 'successful withdrawal' do
    given_i_am_signed_in_as_a_candidate
    and_i_have_an_application_choice_awaiting_provider_decision

    when_i_visit_the_application_dashboard
    and_i_click_the_withdraw_link_on_my_choice
    then_i_see_a_confirmation_page

    when_i_click_to_confirm_withdrawal
    then_my_application_should_be_withdrawn
    and_a_slack_notification_is_sent
    and_the_provider_has_received_an_email

    when_i_try_to_visit_the_withdraw_page
    then_i_see_the_page_not_found
  end

  def given_i_am_signed_in_as_a_candidate
    create_and_sign_in_candidate
  end

  def and_i_have_an_application_choice_awaiting_provider_decision
    form = create(:completed_application_form, :with_completed_references, candidate: current_candidate)
    @application_choice = create(:application_choice, :awaiting_provider_decision, application_form: form)
    @provider_user = create(:provider_user)
    create(:provider_users_provider, provider_id: @application_choice.provider.id, provider_user_id: @provider_user.id)
  end

  def when_i_visit_the_application_dashboard
    visit candidate_interface_application_form_path
  end

  def and_i_click_the_withdraw_link_on_my_choice
    click_link 'Withdraw'
  end

  def then_i_see_a_confirmation_page
    expect(page).to have_content('Confirm')
  end

  def when_i_click_to_confirm_withdrawal
    click_button 'Withdraw my application'
  end

  def then_my_application_should_be_withdrawn
    expect(page).to have_content('Your application has been withdrawn')
  end

  def and_a_slack_notification_is_sent
    expect_slack_message_with_text 'has withdrawn their application'
  end

  def when_i_try_to_visit_the_withdraw_page
    visit candidate_interface_withdraw_path(id: @application_choice.id)
  end

  def then_i_see_the_page_not_found
    expect(page).to have_content('Page not found')
  end

  def and_the_provider_has_received_an_email
    open_email(@provider_user.email_address)
    expect(current_email.subject).to have_content "#{@application_choice.application_form.full_name} withdrew their application"
  end
end
