require 'rails_helper'

RSpec.describe TestApplications do
  include DateComparisonHelper

  it 'generates an application with choices in the given states' do
    create(:course_option, course: create(:course, :open_on_apply))
    create(:course_option, course: create(:course, :open_on_apply))

    choices = TestApplications.new.create_application(recruitment_cycle_year: 2020, states: %i[offer rejected], courses_to_apply_to: Course.all)

    expect(choices.count).to eq(2)
  end

  it 'creates a realistic timeline for a recruited application' do
    courses_we_want = create_list(:course_option, 2, course: create(:course, :open_on_apply)).map(&:course)

    application_choice = TestApplications.new.create_application(recruitment_cycle_year: 2020, states: %i[recruited], courses_to_apply_to: courses_we_want).first

    application_form = application_choice.application_form
    candidate = application_form.candidate

    expect(candidate.created_at).to eq candidate.last_signed_in_at
    expect(candidate.created_at <= application_choice.created_at).to be_truthy
    expect(application_choice.created_at <= application_form.submitted_at).to be_truthy
    expect(application_choice.sent_to_provider_at <= application_choice.offered_at).to be_truthy
    expect(application_choice.offered_at <= application_choice.accepted_at).to be_truthy
  end

  it 'creates a realistic timeline for an offered application' do
    courses_we_want = create_list(:course_option, 2, course: create(:course, :open_on_apply)).map(&:course)

    application_choice = TestApplications.new.create_application(recruitment_cycle_year: 2020, states: %i[offer], courses_to_apply_to: courses_we_want).first

    application_form = application_choice.application_form
    candidate = application_form.candidate
    expect(candidate.created_at <= application_choice.created_at).to be_truthy
    expect(application_choice.created_at <= application_form.submitted_at).to be_truthy
    expect(application_choice.sent_to_provider_at <= application_choice.offered_at).to be_truthy
  end

  it 'attributes actions to candidates', with_audited: true do
    courses_we_want = create_list(:course_option, 1, course: create(:course, :open_on_apply)).map(&:course)

    application_choice = TestApplications.new.create_application(recruitment_cycle_year: 2020, states: %i[recruited], courses_to_apply_to: courses_we_want).first
    application_form = application_choice.application_form
    candidate = application_form.candidate

    submission_audit = application_choice.audits.where("audited_changes @> '{\"status\": [\"unsubmitted\", \"awaiting_provider_decision\"]}'").first
    expect(submission_audit).not_to be_nil
    expect(submission_audit.user).to eq candidate
  end

  it 'attributes actions to provider users', with_audited: true do
    courses_we_want = create_list(:course_option, 1, course: create(:course, :open_on_apply)).map(&:course)

    application_choice = TestApplications.new.create_application(recruitment_cycle_year: 2020, states: %i[recruited], courses_to_apply_to: courses_we_want).first
    provider_user = application_choice.provider.provider_users.first

    offer_audit = application_choice.reload.audits.where("audited_changes @> '{\"status\": [\"recruited\"]}'").first
    expect(offer_audit).not_to be_nil
    expect(offer_audit.user).to eq provider_user
  end

  it 'generates an application for the specified candidate' do
    expected_candidate = create(:candidate)
    courses_we_want = create_list(:course_option, 2, course: create(:course, :open_on_apply)).map(&:course)

    application_choice = TestApplications.new.create_application(
      recruitment_cycle_year: 2021,
      states: %i[unsubmitted_with_completed_references],
      courses_to_apply_to: courses_we_want,
      candidate: expected_candidate,
    ).first

    candidate = application_choice.application_form.candidate

    expect(candidate).to eq expected_candidate
  end

  it 'throws an exception if there are not enough courses to apply to' do
    expect {
      TestApplications.new.create_application(recruitment_cycle_year: 2020, states: %i[offer], courses_to_apply_to: [])
    }.to raise_error(/Not enough distinct courses/)
  end

  it 'throws an exception if zero courses are specified per application' do
    expect {
      TestApplications.new.create_application(recruitment_cycle_year: 2020, states: [], courses_to_apply_to: [])
    }.to raise_error(/You cannot have zero courses per application/)
  end

  describe 'supplying our own courses' do
    it 'creates applications only for the supplied courses' do
      course_we_want = create(:course_option, course: create(:course, :open_on_apply)).course

      choices = TestApplications.new.create_application(recruitment_cycle_year: 2020, states: %i[offer], courses_to_apply_to: [course_we_want])

      expect(choices.first.course).to eq(course_we_want)
    end

    it 'creates the right number of applications' do
      courses_we_want = create_list(:course_option, 2, course: create(:course, :open_on_apply)).map(&:course)

      choices = TestApplications.new.create_application(recruitment_cycle_year: 2020, states: %i[offer], courses_to_apply_to: courses_we_want)

      expect(choices.count).to eq(1)
    end
  end

  describe 'full work history' do
    it 'creates applications with work experience as well as explained and unexplained breaks' do
      create(:course_option, course: create(:course, :open_on_apply))

      choices = TestApplications.new.create_application(recruitment_cycle_year: 2020, courses_to_apply_to: Course.all, states: %i[awaiting_provider_decision])

      expect(choices.count).to eq(1)
      expect(choices.first.application_form.application_work_experiences.count).to eq(2)
      expect(choices.first.application_form.application_work_history_breaks.count).to eq(1)
    end
  end

  describe 'reference completion' do
    it 'completes all references for unsubmitted_with_completed_references applications' do
      courses_we_want = create_list(:course_option, 2, course: create(:course, :open_on_apply)).map(&:course)

      application_choice = TestApplications.new.create_application(recruitment_cycle_year: 2021, states: %i[unsubmitted_with_completed_references], courses_to_apply_to: courses_we_want).first

      references = application_choice.application_form.application_references

      expect(references.all?(&:feedback_provided?)).to be true
    end

    it 'completes all references for other types of application' do
      courses_we_want = create_list(:course_option, 2, course: create(:course, :open_on_apply)).map(&:course)

      application_choice = TestApplications.new.create_application(recruitment_cycle_year: 2021, states: %i[awaiting_provider_decision offer], courses_to_apply_to: courses_we_want).first

      references = application_choice.application_form.application_references

      expect(references.all?(&:feedback_provided?)).to be true
    end

    it 'does not complete any references for unsubmitted applications' do
      courses_we_want = create_list(:course_option, 2, course: create(:course, :open_on_apply)).map(&:course)

      application_choice = TestApplications.new.create_application(recruitment_cycle_year: 2021, states: %i[unsubmitted], courses_to_apply_to: courses_we_want).first

      references = application_choice.application_form.application_references

      expect(references.all?(&:feedback_requested?)).to be true
    end
  end
end
