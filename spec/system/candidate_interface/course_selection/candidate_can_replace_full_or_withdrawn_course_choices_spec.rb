require 'rails_helper'

RSpec.describe 'A course option selected by a candidate has become full or been withdrawn' do
  include CandidateHelper
  include CourseOptionHelpers

  scenario 'when a candidate arrives at the dashboard they can follow the replace course flow' do
    given_the_replace_full_or_withdrawn_application_choices_is_active
    and_i_have_submitted_my_application
    and_one_of_my_application_choices_has_become_full
    and_there_is_another_location_available

    when_i_arrive_at_my_application_dashboard
    then_i_see_that_one_of_my_choices_in_not_available

    given_i_have_two_full_course_choices

    when_i_arrive_at_my_application_dashboard
    then_i_see_that_multiple_choices_are_not_available

    when_i_click_update_my_course_choice
    then_i_see_the_replace_course_choices_page
    and_i_see_my_first_course_choice
    and_i_see_my_second_course_choice

    when_i_click_continue_without_selecting_an_option
    then_i_am_told_i_need_to_select_a_course_choice

    when_i_choose_my_first_course_choice
    and_click_continue
    then_i_arrive_at_the_replace_course_choice_page
    and_i_see_my_first_course_choice

    when_i_click_continue_without_selecting_an_option
    then_i_am_told_i_need_to_select_an_option

    when_i_choose_to_add_a_different_course
    and_click_continue
    then_i_am_told_to_contact_support

    when_i_click_back
    and_i_choose_to_add_a_new_location
    and_click_continue
    then_i_see_the_update_location_page
    and_i_can_see_my_another_choice_of_location

    when_i_click_continue_without_selecting_an_option
    then_i_am_told_i_need_to_select_a_location

    when_i_select_a_location
    and_click_continue
    then_i_see_the_confirm_replacement_course_choice_page

    when_i_click_replace_course_choice
    then_i_arrrive_at_my_dashboard
    and_i_can_see_my_new_course_choice
    and_i_cannot_see_my_old_course_choice
  end

  def given_the_replace_full_or_withdrawn_application_choices_is_active
    FeatureFlag.activate('replace_full_or_withdrawn_application_choices')
  end

  def and_i_have_submitted_my_application
    candidate_completes_application_form
    candidate_submits_application
  end

  def and_one_of_my_application_choices_has_become_full
    @course_option = @application.application_choices.first.course_option
    @course_option.no_vacancies!
  end

  def and_there_is_another_location_available
    @site = create(:site, provider: @course_option.provider)
    @course_option2 = create(:course_option, site: @site, course: @course_option.course)
  end

  def when_i_arrive_at_my_application_dashboard
    visit candidate_interface_application_complete_path
  end

  def then_i_see_that_one_of_my_choices_in_not_available
    expect(page).to have_content 'One of your choices is not available anymore.'
  end

  def given_i_have_two_full_course_choices
    course_option_for_provider(provider: @course_option.provider)
    @application_choice = create(:application_choice, application_form: @application, status: 'awaiting_references')
    @application_choice.course_option.no_vacancies!
  end

  def then_i_see_that_multiple_choices_are_not_available
    expect(page).to have_content 'Some of your choices are not available anymore.'
  end

  def when_i_click_update_my_course_choice
    click_link 'Update your course choice now'
  end

  def then_i_see_the_replace_course_choices_page
    expect(page).to have_current_path candidate_interface_replace_course_choices_path
  end

  def and_i_see_my_first_course_choice
    expect(page).to have_content(@course_option.course.name_and_code)
  end

  def and_i_see_my_second_course_choice
    expect(page).to have_content(@application_choice.course.name_and_code)
  end

  def when_i_click_continue_without_selecting_an_option
    click_button 'Continue'
  end

  def then_i_am_told_i_need_to_select_a_course_choice
    expect(page).to have_content 'Please select a course choice to update.'
  end

  def when_i_choose_my_first_course_choice
    choose "#{@course_option.provider.name} – #{@course_option.course.name_and_code}"
  end

  def and_click_continue
    when_i_click_continue_without_selecting_an_option
  end

  def then_i_arrive_at_the_replace_course_choice_page
    expect(page).to have_current_path candidate_interface_replace_course_choice_path(@course_option.application_choices.first.id)
  end

  def then_i_am_told_i_need_to_select_an_option
    expect(page).to have_content 'Please select an option to update your course choice.'
  end

  def when_i_choose_to_add_a_different_course
    choose 'Choose a different course'
  end

  def then_i_am_told_to_contact_support
    expect(page).to have_content 'You can currently only change the location of your course choice through the service.'
  end

  def when_i_click_back
    click_link 'Back'
  end

  def and_i_choose_to_add_a_new_location
    choose 'Choose a different location'
  end

  def then_i_see_the_update_location_page
    expect(page).to have_content t('page_titles.which_location')
  end

  def and_i_can_see_my_another_choice_of_location
    expect(page).to have_content @course_option2.site.full_address
  end

  def then_i_am_told_i_need_to_select_a_location
    expect(page).to have_content 'Please select a new location.'
  end

  def when_i_select_a_location
    choose @course_option2.site.name
  end

  def then_i_see_the_confirm_replacement_course_choice_page
    expect(page).to have_current_path candidate_interface_confirm_replacement_course_choice_path(@course_option.application_choices.first.id, @course_option2.id)
  end

  def when_i_click_replace_course_choice
    click_link 'Replace course choice'
  end

  def then_i_arrrive_at_my_dashboard
    expect(page).to have_current_path candidate_interface_application_complete_path
  end

  def and_i_can_see_my_new_course_choice
    expect(page).to have_content @course_option2.site.full_address
  end

  def and_i_cannot_see_my_old_course_choice
    expect(page).not_to have_content @course_option.site.full_address
  end
end
