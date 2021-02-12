require 'rails_helper'

RSpec.describe ApplicationChoice, type: :model do
  describe 'auditing', with_audited: true do
    it 'creates audit entries' do
      application_choice = create :application_choice, status: 'unsubmitted'
      expect(application_choice.audits.count).to eq 1
      application_choice.update!(status: 'awaiting_provider_decision')
      expect(application_choice.audits.count).to eq 2
    end

    it 'creates an associated object in each audit record' do
      application_choice = create :application_choice
      expect(application_choice.audits.last.associated).to eq application_choice.application_form
    end

    it 'audit record can be attributed to a candidate' do
      candidate = create :candidate
      application_choice = Audited.audit_class.as_user(candidate) do
        create :application_choice
      end
      expect(application_choice.audits.last.user).to eq candidate
    end
  end

  describe '#course_full?' do
    context 'with 3 options all full' do
      it 'returns true' do
        course = create(:course)
        create_list(:course_option, 3, vacancy_status: :no_vacancies, course: course)
        application_choice = create(:application_choice, course_option: course.course_options.first)
        expect(application_choice.course_full?).to be true
      end
    end

    context 'with 2 options only 1 full' do
      it 'returns false' do
        course = create(:course)
        course_option_without_vacancies = create(:course_option, vacancy_status: :no_vacancies, course: course)
        create(:course_option, vacancy_status: :vacancies, course: course)
        application_choice = create :application_choice, course_option: course_option_without_vacancies
        expect(application_choice.course_full?).to be false
      end
    end
  end

  describe '#site_full?' do
    context 'with 3 options all full' do
      it 'returns true' do
        course = create(:course)
        create_list(:course_option, 3, vacancy_status: :no_vacancies, course: course)
        application_choice = create(:application_choice, course_option: course.course_options.first)
        expect(application_choice.site_full?).to be true
      end
    end

    context 'with 2 options only 1 full' do
      it 'returns true' do
        course = create(:course)
        course_option_without_vacancies = create(:course_option, vacancy_status: :no_vacancies, course: course)
        create(:course_option, vacancy_status: :vacancies, course: course)
        application_choice = create :application_choice, course_option: course_option_without_vacancies
        expect(application_choice.site_full?).to be true
      end
    end

    context 'with 2 options for same site only 1 full' do
      it 'returns true' do
        course = create(:course)
        site = create(:site, provider: course.provider)
        course_option_without_vacancies = create(:course_option, vacancy_status: :no_vacancies, course: course, site: site, study_mode: 'full_time')
        create(:course_option, vacancy_status: :vacancies, course: course, site: site, study_mode: 'part_time')
        application_choice = create :application_choice, course_option: course_option_without_vacancies
        expect(application_choice.site_full?).to be false
      end
    end
  end

  describe '#course_study_mode_full?' do
    context 'with option that has vacancies' do
      it 'returns false' do
        course = create(:course)
        create(:course_option, vacancy_status: :vacancies, course: course)
        application_choice = create(:application_choice, course_option: course.course_options.first)
        expect(application_choice.study_mode_full?).to be false
      end
    end

    context 'with 2 options only 1 full' do
      it 'returns true' do
        course = create(:course)
        course_option_without_vacancies = create(:course_option, vacancy_status: :no_vacancies, course: course)
        create(:course_option, vacancy_status: :vacancies, course: course)
        application_choice = create :application_choice, course_option: course_option_without_vacancies
        expect(application_choice.study_mode_full?).to be true
      end
    end

    context 'with 2 options for same site only 1 full' do
      it 'returns true' do
        course = create(:course)
        site = create(:site, provider: course.provider)
        course_option_without_vacancies = create(:course_option, vacancy_status: :no_vacancies, course: course, site: site, study_mode: 'full_time')
        create(:course_option, vacancy_status: :vacancies, course: course, site: site, study_mode: 'part_time')
        application_choice = create :application_choice, course_option: course_option_without_vacancies
        expect(application_choice.study_mode_full?).to be true
      end
    end
  end

  describe '#feedback_provided?' do
    it 'returns true if simple rejection reason is provided' do
      application_choice = build(:application_choice, :with_rejection)

      expect(application_choice.feedback_provided?).to be true
    end

    it 'returns true if structured rejection reasons are provided' do
      application_choice = build(:application_choice, :with_structured_rejection_reasons)

      expect(application_choice.feedback_provided?).to be true
    end

    it 'returns false if no feedback for the candidate is provided' do
      application_choice = build(:application_choice)

      expect(application_choice.feedback_provided?).to be false
    end
  end

  describe 'validations' do
    subject(:application_choice) { create(:application_choice) }

    it { is_expected.to validate_uniqueness_of(:course_option).scoped_to(:application_form_id) }
  end

  describe '#structured_rejection_reasons' do
    it 'are serialized and rehydrateable' do
      reasons = ReasonsForRejection.new(
        candidate_behaviour_y_n: 'Yes',
        candidate_behaviour_what_did_the_candidate_do: %w[other],
        candidate_behaviour_other: 'Used the wrong spoon for soup',
      )

      application_choice = create(:application_choice)
      application_choice.update!(structured_rejection_reasons: reasons)

      rehydrated_reasons = ReasonsForRejection.new(application_choice.reload.structured_rejection_reasons)
      expect(rehydrated_reasons.candidate_behaviour_y_n).to eq('Yes')
      expect(rehydrated_reasons.candidate_behaviour_what_did_the_candidate_do).to eq(%w[other])
      expect(rehydrated_reasons.candidate_behaviour_other).to eq('Used the wrong spoon for soup')
    end
  end
end
