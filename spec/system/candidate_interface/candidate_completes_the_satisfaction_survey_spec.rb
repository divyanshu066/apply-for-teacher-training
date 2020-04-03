require 'rails_helper'

RSpec.describe 'Candidate satisfaction survey' do
  include CandidateHelper

  scenario 'Candidate completes the survey' do
    given_the_satisfaction_survey_flag_is_active
    and_the_training_with_a_disability_flag_is_active

    when_the_candidate_completes_and_submits_their_application
    then_they_should_be_asked_to_give_feedback

    when_they_click_give_feedback
    then_they_should_see_the_recommendation_page

    when_i_choose_1
    and_click_continue
    then_i_see_the_complexity_page

    when_i_choose_5
    and_click_continue
    then_i_see_the_ease_of_use_page

    when_i_choose_1
    and_click_continue
    then_i_see_the_help_needed_page

    when_i_choose_1
    and_click_continue
    then_i_see_the_organisation_page

    when_i_choose_1
    and_click_continue
    then_i_see_the_consistency_page

    when_i_choose_1
    and_click_continue
    then_i_see_the_adaptability_page

    when_i_choose_1
    and_click_continue
    then_i_see_the_awkward_page

    when_i_choose_1
    and_click_continue
    then_i_see_the_confidence_page

    when_i_choose_1
    and_click_continue
    then_i_see_the_needed_additional_learning_page

    when_i_choose_1
    and_click_continue
    then_i_see_the_improvements_page

    when_i_give_my_feedback
    and_click_continue
    then_i_see_the_other_information_page

    when_i_give_my_other_feedback
    and_click_continue
    then_i_see_the_contact_page

    when_i_choose_yes
    and_click_continue
    then_i_see_the_thank_you_page
  end

  def given_the_satisfaction_survey_flag_is_active
    FeatureFlag.activate('satisfaction_survey')
  end

  def and_the_training_with_a_disability_flag_is_active
    FeatureFlag.activate('training_with_a_disability')
  end

  def when_the_candidate_completes_and_submits_their_application
    candidate_completes_application_form
    candidate_submits_application
  end

  def then_they_should_be_asked_to_give_feedback
    expect(page).to have_content('Your feedback will help us improve.')
  end

  def when_they_click_give_feedback
    click_link 'Give feedback'
  end

  def then_they_should_see_the_recommendation_page
    expect(page).to have_content(t('page_titles.recommendation'))
  end

  def when_i_choose_1
    choose '1 - strongly agree'
  end

  def and_click_continue
    click_button 'Continue'
  end

  def then_i_see_the_complexity_page
    expect(page).to have_content(t('page_titles.complexity'))
  end

  def when_i_choose_5
    choose '5 - strongly disagree'
  end

  def then_i_see_the_ease_of_use_page
    expect(page).to have_content(t('page_titles.ease_of_use'))
  end

  def then_i_see_the_help_needed_page
    expect(page).to have_content(t('page_titles.help_needed'))
  end

  def then_i_see_the_organisation_page
    expect(page).to have_content(t('page_titles.organisation'))
  end

  def then_i_see_the_consistency_page
    expect(page).to have_content(t('page_titles.consistency'))
  end

  def then_i_see_the_adaptability_page
    expect(page).to have_content(t('page_titles.adaptability'))
  end

  def then_i_see_the_awkward_page
    expect(page).to have_content(t('page_titles.awkward'))
  end

  def then_i_see_the_confidence_page
    expect(page).to have_content(t('page_titles.confidence'))
  end

  def then_i_see_the_needed_additional_learning_page
    expect(page).to have_content(t('page_titles.needed_additional_learning'))
  end

  def then_i_see_the_improvements_page
    expect(page).to have_content(t('page_titles.improvements'))
  end

  def when_i_give_my_feedback
    page.find('#candidate-interface-satisfaction-survey-form-answer-field').set('No it was perfect.')
  end

  def then_i_see_the_other_information_page
    expect(page).to have_content(t('page_titles.other_information'))
  end

  def when_i_give_my_other_feedback
    page.find('#candidate-interface-satisfaction-survey-form-answer-field').set('None.')
  end

  def then_i_see_the_contact_page
    expect(page).to have_content(t('page_titles.contact'))
  end

  def when_i_choose_yes
    choose 'Yes, you can contact me'
  end

  def then_i_see_the_thank_you_page
    expect(page).to have_content(t('page_titles.thank_you'))
  end
end
