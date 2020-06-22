require 'rails_helper'

RSpec.describe CandidateInterface::GcseQualificationDetailsForm, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:grade).on(:grade) }
    it { is_expected.to validate_presence_of(:award_year).on(:award_year) }
    it { is_expected.to validate_length_of(:grade).is_at_most(6).on(:grade) }

    context 'when qualification type is GCSE' do
      let(:form) { CandidateInterface::GcseQualificationDetailsForm.build_from_qualification(qualification) }
      let(:qualification) { FactoryBot.build_stubbed(:application_qualification, qualification_type: 'gcse', level: 'gcse') }

      it 'returns no errors if grade is valid' do
        valid_grades = ['A*A*A*', 'ABC', 'AA', '863', 'a*a*a*', 'A B C', 'A-B-C']

        valid_grades.each do |grade|
          form.grade = grade
          form.validate

          expect(form.errors[:grade]).to be_empty
        end
      end

      it 'return validation error if grade is invalid' do
        invalid_grades = %w[012 XYZ]

        invalid_grades.each do |grade|
          form.grade = grade
          form.validate(:grade)
          expect(form.errors[:grade]).to include('Enter a real grade')
        end
      end

      it 'logs validation errors if grade is invalid' do
        allow(Rails.logger).to receive(:info)
        form.grade = 'XYZ'

        form.save_grade

        expect(Rails.logger).to have_received(:info).with(
          'Validation error: {:field=>"grade", :error_messages=>"Enter a real grade", :value=>"XYZ"}',
        )
      end
    end

    context 'when qualification type is GCE O LEVEL' do
      let(:form) { CandidateInterface::GcseQualificationDetailsForm.build_from_qualification(qualification) }
      let(:qualification) { FactoryBot.build_stubbed(:application_qualification, qualification_type: 'gce_o_level', level: 'gcse') }

      it 'returns no errors if grade is valid' do
        valid_grades = ['ABC', 'AB', 'AA', 'abc', 'A B C', 'A-B-C']

        valid_grades.each do |grade|
          form.grade = grade
          form.validate

          expect(form.errors[:grade]).to be_empty
        end
      end

      it 'return validation error if grade is invalid' do
        invalid_grades = %w[123 A* XYZ]

        invalid_grades.each do |grade|
          form.grade = grade
          form.validate(:grade)

          expect(form.errors[:grade]).to include('Enter a real grade')
        end
      end
    end

    context 'when qualification type is Scottish National 5' do
      let(:form) { CandidateInterface::GcseQualificationDetailsForm.build_from_qualification(qualification) }
      let(:qualification) { FactoryBot.build_stubbed(:application_qualification, qualification_type: 'scottish_national_5', level: 'gcse') }

      it 'returns no errors if grade is valid' do
        valid_grades = ['AAA', 'AAB', '765', 'CBD', 'aaa', 'C B D', 'C-B-D']

        valid_grades.each do |grade|
          form.grade = grade
          form.validate

          expect(form.errors[:grade]).to be_empty
        end
      end

      it 'return validation error if grade is invalid' do
        invalid_grades = %w[89 AE A*]

        invalid_grades.each do |grade|
          form.grade = grade
          form.validate(:grade)

          expect(form.errors[:grade]).to include('Enter a real grade')
        end
      end
    end
  end

  context 'when saving qualification details' do
    qualification = ApplicationQualification.new
    form = CandidateInterface::GcseQualificationDetailsForm.build_from_qualification(qualification)

    describe '#save_grade' do
      it 'return false if not valid' do
        expect(form.save_grade).to eq(false)
      end

      it 'updates qualification details if valid' do
        application_form = create(:application_form)
        qualification = ApplicationQualification.create(level: 'gcse', application_form: application_form)
        details_form = CandidateInterface::GcseQualificationDetailsForm.build_from_qualification(qualification)

        details_form.grade = 'AB'

        details_form.save_grade
        qualification.reload

        expect(qualification.grade).to eq('AB')
      end
    end

    describe '#save_year' do
      it 'return false if not valid' do
        expect(form.save_year).to eq(false)
      end

      it 'returns validation error if award_year is in the future' do
        Timecop.freeze(Time.zone.local(2008, 1, 1)) do
          details_form = CandidateInterface::GcseQualificationDetailsForm.new(award_year: '2009')

          details_form.save_year

          expect(details_form.errors[:award_year]).to include('Enter a year before 2009')
        end
      end

      it 'updates qualification details if valid' do
        application_form = create(:application_form)
        qualification = ApplicationQualification.create(level: 'gcse', application_form: application_form)
        details_form = CandidateInterface::GcseQualificationDetailsForm.build_from_qualification(qualification)

        details_form.award_year = '1990'

        details_form.save_year
        qualification.reload

        expect(qualification.award_year).to eq('1990')
      end
    end
  end
end