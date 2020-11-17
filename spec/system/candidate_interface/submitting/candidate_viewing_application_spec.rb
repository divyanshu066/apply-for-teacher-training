require 'rails_helper'

RSpec.feature 'Viewing their new application' do
  include CandidateHelper

  scenario 'Signed in candidate with no application choices' do
    given_i_am_signed_in
    when_i_visit_the_site
    then_i_should_see_that_i_have_made_no_choices

    when_i_visit_the_review_page
    then_i_am_on_the_application_form_page

    when_i_visit_the_complete_page
    then_i_am_on_the_application_form_page

    when_i_visit_the_submit_success_page
    then_i_am_on_the_application_form_page
  end

  def given_i_am_signed_in
    create_and_sign_in_candidate
  end

  def when_i_visit_the_site
    visit candidate_interface_application_form_path
  end

  def then_i_should_see_that_i_have_made_no_choices
    expect(page).to have_content(t('application_form.courses.intro'))
  end

  def when_i_visit_the_review_page
    visit candidate_interface_application_review_submitted_path
  end

  def when_i_visit_the_complete_page
    visit candidate_interface_application_complete_path
  end

  def when_i_visit_the_submit_success_page
    visit candidate_interface_application_submit_success_path
  end

  def then_i_am_on_the_application_form_page
    then_i_should_see_that_i_have_made_no_choices
  end
end