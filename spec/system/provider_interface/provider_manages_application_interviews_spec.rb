require 'rails_helper'

RSpec.describe 'A Provider viewing an individual application', with_audited: true do
  include CourseOptionHelpers
  include DfESignInHelpers
  include ProviderUserPermissionsHelper

  let(:application_choice) { create(:application_choice, :awaiting_provider_decision, course_option: course_option) }
  let(:course_option) { course_option_for_provider_code(provider_code: 'ABC') }

  around do |example|
    Timecop.freeze(Time.zone.local(2020, 3, 1, 12, 0, 0)) do
      example.run
    end
  end

  before do
    FeatureFlag.activate(:interviews)
  end

  scenario 'can view, create and cancel interviews' do
    given_i_am_a_provider_user_with_dfe_sign_in
    and_i_am_permitted_to_see_applications_for_my_provider
    and_i_am_permitted_to_make_decisions_for_my_provider
    and_i_sign_in_to_the_provider_interface

    when_i_visit_that_application_in_the_provider_interface
    and_i_click_set_up_an_interview
    and_i_fill_out_the_interview_form(days_in_future: 1, time: '12pm')
    and_i_click_send_interview_details
    then_i_see_a_success_message
    and_an_interview_has_been_created('2 March 2020')

    and_i_can_set_up_another_interview(days_in_future: 2)
    and_another_interview_has_been_created('3 March 2020')

    when_i_change_the_interview_details
    then_i_can_see_interview_was_updated

    when_i_click_to_cancel_an_interview
    and_i_do_not_enter_a_cancellation_reason
    then_i_see_a_validation_error

    when_i_enter_a_valid_cancellation_reason
    then_i_see_the_check_page_with_working_edit_links

    when_i_confirm_the_cancellation
    i_can_see_the_application_is_still_in_the_interviewing_state
    and_i_can_see_the_second_interview

    when_i_cancel_an_interview
    i_can_see_the_application_is_awaiting_provider_decision
    and_the_interview_tab_is_not_available
  end

  def given_i_am_a_provider_user_with_dfe_sign_in
    provider_exists_in_dfe_sign_in
  end

  def and_i_am_permitted_to_see_applications_for_my_provider
    provider_user_exists_in_apply_database
  end

  def and_i_am_permitted_to_make_decisions_for_my_provider
    permit_make_decisions!
  end

  def when_i_visit_that_application_in_the_provider_interface
    visit provider_interface_application_choice_path(application_choice)
  end

  def and_i_click_set_up_an_interview
    click_on 'Set up interview'
  end

  def i_can_set_up_an_interview
    visit new_provider_interface_application_choice_interview_path(application_choice, date_and_time: '2021-2-4')
    expect(page).to have_content('Interview successfully created')
  end

  def and_i_can_set_up_another_interview(days_in_future:)
    and_i_click_set_up_an_interview
    and_i_fill_out_the_interview_form(days_in_future: days_in_future, time: '7pm')
    and_i_click_send_interview_details
    then_i_see_a_success_message
  end

  def and_i_fill_out_the_interview_form(days_in_future:, time:)
    tomorrow = days_in_future.day.from_now
    fill_in 'Day', with: tomorrow.day
    fill_in 'Month', with: tomorrow.month
    fill_in 'Year', with: tomorrow.year

    fill_in 'Time', with: time

    fill_in 'Address or online meeting details', with: 'N/A'

    click_on 'Continue'
  end

  def and_i_click_send_interview_details
    click_on 'Send interview details'
  end

  def then_i_see_a_success_message
    expect(page).to have_content 'Interview set up'
  end

  def and_an_interview_has_been_created(date)
    within('.app-interviews') do
      expect(page).to have_content(date)
    end
  end

  alias_method :and_another_interview_has_been_created, :and_an_interview_has_been_created

  def when_i_change_the_interview_details
    click_on 'Change details', match: :first

    expect(page).to have_field('Day', with: '2')
    expect(page).to have_field('Month', with: '3')
    expect(page).to have_field('Year', with: '2020')
    expect(page).to have_field('Time', with: '12:00pm')
    expect(page).to have_field('Address or online meeting details', with: 'N/A')
    expect(page).to have_field('Additional details (optional)', with: '')

    fill_in 'Day', with: '4'
    fill_in 'Time', with: '10am'
    fill_in 'Address or online meeting details', with: 'Zoom meeting'
    fill_in 'Additional details (optional)', with: 'Business casual'

    click_on 'Continue'
  end

  def then_i_can_see_interview_was_updated
    expect(page).to have_content('Check and send new interview details')
    expect(page).to have_content("Date\n4 March 2020")
    expect(page).to have_content("Time\n10am")
    expect(page).to have_content("Address or online meeting details\nZoom meeting")
    expect(page).to have_content("Additional details\nBusiness casual")

    click_on 'Change', match: :first

    fill_in 'Additional details (optional)', with: 'Business casual, first impressions are important.'

    click_on 'Continue'

    expect(page).to have_content("Additional details\nBusiness casual, first impressions are important")

    click_on 'Send new interview details'

    expect(page).to have_content('Interview changed')

    expect(page).to have_content("Upcoming interviews\n4 March 2020 at 10am")
    expect(page).to have_content("Address or online meeting details\nZoom meeting")
    expect(page).to have_content("Additional details\nBusiness casual, first impressions are important")
  end

  def when_i_click_to_cancel_an_interview
    first(:link, 'Cancel').click
  end

  def and_i_do_not_enter_a_cancellation_reason
    click_on 'Continue'
  end

  def then_i_see_a_validation_error
    expect(page).to have_content 'Enter reason for cancelling interview'
  end

  def when_i_enter_a_valid_cancellation_reason
    fill_in 'provider_interface_cancel_interview_wizard[cancellation_reason]', with: 'A cancellation reason'
    click_on 'Continue'
  end

  def then_i_see_the_check_page_with_working_edit_links
    expect(page).to have_content 'A cancellation reason'
    expect(page).to have_content 'Change'

    click_link 'Change'
    expect(page).to have_field('provider_interface_cancel_interview_wizard[cancellation_reason]', with: 'A cancellation reason')
    click_on 'Continue'
  end

  def when_i_confirm_the_cancellation
    click_on 'Send cancellation'
    expect(page).to have_content('Interview cancelled')
  end

  def when_i_cancel_an_interview
    when_i_click_to_cancel_an_interview
    when_i_enter_a_valid_cancellation_reason
    when_i_confirm_the_cancellation
  end

  def i_can_see_the_application_is_still_in_the_interviewing_state
    expect(page).to have_content('Interviewing')
  end

  def and_i_can_see_the_second_interview
    visit provider_interface_application_choice_interviews_path(application_choice)

    expect(page).to have_content('Upcoming interviews')
    expect(page).to have_css('.app-interviews__interview')
  end

  def i_can_see_the_application_is_awaiting_provider_decision
    expect(page).to have_content('Received')
  end

  def and_the_interview_tab_is_not_available
    within '.app-tab-navigation__list' do
      expect(page).not_to have_content('Interviews')
    end
  end
end
