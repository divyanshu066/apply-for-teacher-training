require 'rails_helper'

RSpec.describe Course, type: :model do
  describe 'a valid course' do
    subject(:course) { create(:course) }

    it { is_expected.to validate_presence_of :level }
    it { is_expected.to validate_uniqueness_of(:code).scoped_to(%i[recruitment_cycle_year provider_id]) }
  end

  describe '#currently_has_both_study_modes_available?' do
    it 'is true when a course has full time and part time course options' do
      course_option1 = build_stubbed(:course_option, :full_time)
      course_option2 = build_stubbed(:course_option, :part_time)
      course = build_stubbed(:course, course_options: [course_option1, course_option2])

      expect(course.currently_has_both_study_modes_available?).to be true
    end

    it 'is false when a course only has full time or part time course options' do
      course_option1 = build_stubbed(:course_option, :full_time)
      course_option2 = build_stubbed(:course_option, :part_time)
      course1 = build_stubbed(:course, course_options: [course_option1])
      course2 = build_stubbed(:course, course_options: [course_option2])

      expect(course1.currently_has_both_study_modes_available?).to be false
      expect(course2.currently_has_both_study_modes_available?).to be false
    end
  end

  describe '#available_study_modes_from_options' do
    it 'returns an array of unique study modes for a courses course options' do
      course_option1 = build_stubbed(:course_option, :full_time)
      course_option2 = build_stubbed(:course_option, :full_time)
      course_option3 = build_stubbed(:course_option, :part_time)
      course = build_stubbed(:course, course_options: [course_option1, course_option2, course_option3])

      expect(course.available_study_modes_from_options).to eq [course_option1.study_mode, course_option3.study_mode]
    end

    it 'does not return course_options which have been invalidated by the SyncCoursesFromFind job' do
      valid_course_option = build_stubbed(:course_option, :full_time)
      invalid_course_option = build_stubbed(:course_option, :part_time, site_still_valid: false)
      course = build_stubbed(:course, course_options: [valid_course_option, invalid_course_option])

      expect(course.available_study_modes_from_options).to eq [valid_course_option.study_mode]
    end
  end

  describe '#full?' do
    subject(:course) { create(:course) }

    context 'when there are no course options' do
      it 'returns true' do
        expect(course.full?).to be true
      end
    end

    context 'when a subset of course options have vacancies' do
      before do
        create(:course_option, course: course, vacancy_status: 'vacancies')
        create(:course_option, course: course, vacancy_status: 'no_vacancies')
      end

      it 'returns false' do
        expect(course.full?).to be false
      end
    end

    context 'when no course options have vacancies' do
      before do
        create(:course_option, course: course, vacancy_status: 'no_vacancies')
        create(:course_option, course: course, vacancy_status: 'no_vacancies')
      end

      it 'returns false' do
        expect(course.full?).to be true
      end
    end
  end

  describe '#in_previous_cycle' do
    it 'returns nil when there is no equivalent in the previous cycle' do
      course = create(:course)

      expect(course.in_previous_cycle).to be_nil
    end

    it 'returns the equivalent in the previous cycle when there is one' do
      provider = create(:provider)
      course_in_previous_cycle = create(:course, code: 'ABC', provider: provider, recruitment_cycle_year: 2019)

      course = create(:course, code: 'ABC', provider: provider, recruitment_cycle_year: 2020)

      expect(course.in_previous_cycle).to eq course_in_previous_cycle
    end
  end
end
