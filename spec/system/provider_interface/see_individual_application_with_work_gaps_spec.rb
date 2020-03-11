require 'rails_helper'

RSpec.describe 'A Provider viewing an individual application' do
  include CourseOptionHelpers
  include DfESignInHelpers

  around do |example|
    Timecop.freeze(Time.zone.local(2020, 3, 1, 12, 0, 0)) do
      example.run
    end
  end

  scenario 'the application data is visible' do
    given_i_am_a_provider_user_with_dfe_sign_in
    and_the_work_breaks_feature_flag_is_active
    and_my_organisation_has_received_an_application
    and_i_am_permitted_to_see_applications_for_my_provider
    and_i_sign_in_to_the_provider_interface

    when_i_visit_that_application_in_the_provider_interface

    then_i_should_see_the_candidates_degrees
    and_i_should_see_the_candidates_gcses
    and_i_should_see_the_candidates_other_qualifications
    and_i_should_see_the_candidates_work_history
    and_i_should_see_the_candidates_volunteering_history
    and_i_should_see_the_candidates_personal_statement
    and_i_should_see_the_candidates_language_skills
    and_i_should_see_the_candidates_references
  end

  def given_i_am_a_provider_user_with_dfe_sign_in
    provider_exists_in_dfe_sign_in
  end

  def and_the_work_breaks_feature_flag_is_active
    FeatureFlag.activate('provider_interface_work_breaks')
  end

  def and_i_am_permitted_to_see_applications_for_my_provider
    provider_user_exists_in_apply_database
  end

  def and_my_organisation_has_received_an_application
    course_option = course_option_for_provider_code(provider_code: 'ABC')
    application_form = create(:application_form,
                              submitted_at: Time.zone.now,
                              becoming_a_teacher: 'This is my personal statement',
                              subject_knowledge: 'This is my subject knowledge',
                              interview_preferences: 'Any date is fine',
                              further_information: 'Nothing further to add',
                              english_main_language: true,
                              other_language_details: 'I also speak Spanish and German')

    create_list(:application_qualification, 1, application_form: application_form, level: :degree)
    create_list(:application_qualification, 2, application_form: application_form, level: :gcse)
    create_list(:application_qualification, 3, application_form: application_form, level: :other)

    create(:application_work_experience,
           application_form: application_form,
           role: 'Smuggler',
           organisation: 'The Empire',
           details: 'I used to work for The Empire',
           working_pattern: 'Working pattern at the Empire',
           working_with_children: false,
           start_date: 36.months.ago,
           end_date: 30.months.ago,
           commitment: 'part_time')

    create(:application_work_experience,
           application_form: application_form,
           role: 'Bounty Hunter',
           organisation: 'The Empire',
           details: 'I used to work for The Empire',
           working_pattern: 'Working pattern at the Empire',
           working_with_children: false,
           start_date: 24.months.ago,
           end_date: 18.months.ago,
           commitment: 'full_time')

    create(:application_work_history_break,
           application_form: application_form,
           reason: 'Retraining to become a bounty hunter',
           start_date: 30.months.ago,
           end_date: 24.months.ago)

    create(:application_volunteering_experience,
           application_form: application_form,
           role: 'Defence co-ordinator',
           organisation: 'Rebel Alliance',
           details: 'Worked with children to help them survive clone attacks',
           working_with_children: true,
           start_date: 10.months.ago,
           end_date: nil)

    create(:reference,
           application_form: application_form,
           name: 'R2D2',
           email_address: 'r2d2@rebellion.org',
           relationship: 'Astromech droid',
           feedback: 'beep boop beep')

    create(:reference,
           application_form: application_form,
           name: 'C3PO',
           email_address: 'c3p0@rebellion.org',
           relationship: 'Companion droid',
           feedback: 'The possibility of successfully navigating training is approximately three thousand seven hundred and twenty to one')

    @application_choice = create(:submitted_application_choice,
                                 course_option: course_option,
                                 application_form: application_form)
  end

  def when_i_visit_that_application_in_the_provider_interface
    visit provider_interface_application_choice_path(@application_choice)
  end

  def then_i_should_see_the_candidates_degrees
    expect(page).to have_selector('[data-qa="qualifications-table-degree"] tbody tr', count: 1)
  end

  def and_i_should_see_the_candidates_gcses
    expect(page).to have_selector('[data-qa="qualifications-table-gcse-or-equivalent"] tbody tr', count: 2)
  end

  def and_i_should_see_the_candidates_other_qualifications
    expect(page).to have_selector('[data-qa="qualifications-table-academic-or-other-qualification"] tbody tr', count: 3)
  end

  def and_i_should_see_the_candidates_work_history
    within 'div[data-qa="work-history"]' do
      within 'div.app-experience__item:eq(1)' do
        expect(page).to have_content 'Unexplained break (2 years and 1 month)'
        expect(page).to have_content 'February 2015 - March 2017'
      end

      within 'div.app-experience__item:eq(2)' do
        expect(page).to have_content 'Smuggler - Part-time'
        expect(page).to have_content 'March 2017 - September 2017'
        expect(page).to have_content 'The Empire'
        expect(page).to have_content 'I used to work for'
        expect(page).not_to have_content 'Worked with children'
      end

      within 'div.app-experience__item:eq(3)' do
        expect(page).to have_content 'Break (6 months)'
        expect(page).to have_content 'September 2017 - March 2018'
      end

      within 'div.app-experience__item:eq(4)' do
        expect(page).to have_content 'Bounty Hunter - Full-time'
        expect(page).to have_content 'March 2018 - September 2018'
      end

      within 'div.app-experience__item:eq(5)' do
        expect(page).to have_content 'Unexplained break (1 year and 6 months)'
        expect(page).to have_content 'September 2018 - March 2020'
      end
    end
  end

  def and_i_should_see_the_candidates_volunteering_history
    within '[data-qa="volunteering"]' do
      expect(page).to have_content 'Defence co-ordinator'
      expect(page).to have_content 'Rebel Alliance'
      expect(page).to have_content 'survive clone attacks'
      expect(page).to have_content 'Worked with children'
      expect(page).to have_content 'May 2019 - Present'
    end
  end

  def and_i_should_see_the_candidates_personal_statement
    expect(page).to have_content 'This is my personal statement'
    expect(page).to have_content 'This is my subject knowledge'
    expect(page).to have_content 'Any date is fine'
    expect(page).to have_content 'Nothing further to add'
  end

  def and_i_should_see_the_candidates_language_skills
    within '[data-qa="language-skills"]' do
      expect(page).to have_content 'Yes'
      expect(page).to have_content 'I also speak Spanish and German'
    end
  end

  def and_i_should_see_the_candidates_references
    expect(page).to have_selector('[data-qa="reference"]', count: 2)

    expect(page).to have_content 'R2D2'
    expect(page).to have_content 'r2d2@rebellion.org'
    expect(page).to have_content 'Astromech droid'
    expect(page).to have_content 'beep boop beep'

    expect(page).to have_content 'C3PO'
    expect(page).to have_content 'c3p0@rebellion.org'
    expect(page).to have_content 'Companion droid'
    expect(page).to have_content 'The possibility of successfully'
  end
end