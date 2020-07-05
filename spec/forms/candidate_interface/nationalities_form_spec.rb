require 'rails_helper'

RSpec.describe CandidateInterface::NationalitiesForm, type: :model do
  let(:data) do
    {
      first_nationality: NATIONALITY_DEMONYMS.sample,
      second_nationality: NATIONALITY_DEMONYMS.sample,
    }
  end

  let(:form_data) do
    {
      first_nationality: data[:first_nationality],
      second_nationality: data[:second_nationality],
    }
  end

  describe '.build_from_application' do
    it 'creates an object based on the provided ApplicationForm' do
      application_form = ApplicationForm.new(data)
      nationalities = CandidateInterface::NationalitiesForm.build_from_application(
        application_form,
      )
      expect(nationalities).to have_attributes(form_data)
    end
  end

  describe '#save' do
    it 'returns false if not valid' do
      nationalities = CandidateInterface::NationalitiesForm.new

      expect(nationalities.save(ApplicationForm.new)).to eq(false)
    end

    context 'when first nationality is british and the international_personal_details flag on' do
      let(:form_data) { { first_nationality: 'british' } }

      it 'updates the provided ApplicationForm if valid' do
        FeatureFlag.activate('international_personal_details')
        application_form = FactoryBot.create(:application_form)
        nationalities = CandidateInterface::NationalitiesForm.new(form_data)

        expect(nationalities.save(application_form)).to eq(true)
        expect(application_form.first_nationality).to eq 'British'
      end
    end

    context 'when first nationality is other and the international_personal_details flag on' do
      let(:form_data) do
        {
          first_nationality: 'other',
          other_nationality: 'German',
        }
      end

      it 'updates the provided ApplicationForm if valid' do
        FeatureFlag.activate('international_personal_details')
        application_form = FactoryBot.create(:application_form)
        nationalities = CandidateInterface::NationalitiesForm.new(form_data)

        expect(nationalities.save(application_form)).to eq(true)
        expect(application_form.first_nationality).to eq 'German'
      end
    end

    context 'when first nationality is multiple and the international_personal_details flag on' do
      let(:form_data) do
        {
          first_nationality: 'multiple',
          multiple_nationalities: 'German and Austrian',
        }
      end

      it 'updates the provided ApplicationForm if valid' do
        FeatureFlag.activate('international_personal_details')
        application_form = FactoryBot.create(:application_form)
        nationalities = CandidateInterface::NationalitiesForm.new(form_data)

        expect(nationalities.save(application_form)).to eq(true)
        expect(application_form.first_nationality).to eq 'multiple'
        expect(application_form.multiple_nationalities_details).to eq 'German and Austrian'
      end
    end

    context 'with the international_personal_details flag off' do
      it 'updates the provided ApplicationForm if valid' do
        application_form = FactoryBot.create(:application_form)
        nationalities = CandidateInterface::NationalitiesForm.new(form_data)

        expect(nationalities.save(application_form)).to eq(true)
        expect(application_form).to have_attributes(data)
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:first_nationality) }

    it 'validates nationalities against the NATIONALITY_DEMONYMS list' do
      details_with_invalid_nationality = CandidateInterface::NationalitiesForm.new(
        first_nationality: 'Tralfamadorian',
        second_nationality: 'Czechoslovakian',
      )

      details_with_valid_nationality = CandidateInterface::NationalitiesForm.new(
        first_nationality: NATIONALITY_DEMONYMS.sample,
        second_nationality: NATIONALITY_DEMONYMS.sample,
      )

      details_with_valid_nationality.validate
      details_with_invalid_nationality.validate

      expect(details_with_valid_nationality.errors.keys).not_to include :first_nationality
      expect(details_with_valid_nationality.errors.keys).not_to include :second_nationality

      expect(details_with_invalid_nationality.errors.keys).to include :first_nationality
      expect(details_with_invalid_nationality.errors.keys).to include :second_nationality
    end
  end
end
