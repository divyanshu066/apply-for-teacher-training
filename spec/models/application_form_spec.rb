require 'rails_helper'

RSpec.describe ApplicationForm do
  it 'sets a unique support reference upon creation' do
    create(:application_form, support_reference: 'AB1234')
    allow(GenerateSupportReference).to receive(:call).and_return('AB1234', 'OK1234')

    application_form = create(:application_form)

    expect(application_form.support_reference).to eql('OK1234')
  end

  describe 'before_save' do
    it 'touches the application choice when a field affecting the application choice is changed' do
      application_form = create(:completed_application_form, application_choices_count: 1)

      expect { application_form.update(first_name: 'a new name') }
        .to(change { application_form.application_choices.first.updated_at })
    end

    it 'does not touch the application choice when a field not affecting the application choice is changed' do
      application_form = create(:completed_application_form, application_choices_count: 1)

      expect { application_form.update(latitude: '0.12343') }
        .not_to(change { application_form.application_choices.first.updated_at })
    end
  end

  describe 'after_touch' do
    it 'touches the application choice when touched by a related model' do
      application_form = create(:completed_application_form, with_gcses: true, application_choices_count: 1)

      expect { application_form.maths_gcse.update!(grade: 'D') }
        .to(change { application_form.application_choices.first.updated_at })
    end
  end

  describe 'after_commit' do
    describe '#geocode_address_if_required' do
      it 'invokes geocoding of UK addresses on create' do
        allow(GeocodeApplicationAddressWorker).to receive(:perform_async)
        application_form = build(:completed_application_form)
        application_form.save!

        expect(GeocodeApplicationAddressWorker).to have_received(:perform_async).with(application_form.id)
      end

      it 'invokes geocoding of UK addresses on update' do
        allow(GeocodeApplicationAddressWorker).to receive(:perform_async)
        application_form = create(:completed_application_form)

        address_attributes = %i[address_line1 address_line2 address_line3 address_line4 postcode country]
        address_attributes.each do |address_attr|
          application_form.update!(address_attr => 'foo')
        end

        expected_calls_to_worker = address_attributes.size + 1 # Each update plus the initial create
        expect(GeocodeApplicationAddressWorker)
          .to have_received(:perform_async)
          .with(application_form.id)
          .exactly(expected_calls_to_worker).times
      end

      it 'does not invoke geocoding for international addresses' do
        allow(GeocodeApplicationAddressWorker).to receive(:perform_async)
        application_form = build(:completed_application_form, :international_address)
        application_form.save!

        expect(GeocodeApplicationAddressWorker).not_to have_received(:perform_async).with(application_form.id)
      end

      it 'does not invoke geocoding if address fields have not been changed' do
        allow(GeocodeApplicationAddressWorker).to receive(:perform_async)
        application_form = build(:application_form)
        application_form.save!
        application_form.update!(phone_number: 111111)

        expect(GeocodeApplicationAddressWorker).not_to have_received(:perform_async).with(application_form.id)
      end

      it 'clears existing coordinates if address changed to international' do
        allow(GeocodeApplicationAddressWorker).to receive(:perform_async)
        application_form = create(:completed_application_form, latitude: 1.5, longitude: 0.2)
        application_form.update!(address_type: :international)

        expect([application_form.latitude, application_form.longitude]).to eq [nil, nil]
        expect(GeocodeApplicationAddressWorker)
          .to have_received(:perform_async)
          .with(application_form.id)
          .exactly(1).times # The initial create only
      end
    end
  end

  describe '#previous_application_form' do
    it 'refers to the previous application' do
      previous_application_form = create(:application_form)
      application_form = create(:application_form, previous_application_form_id: previous_application_form.id)

      expect(application_form.previous_application_form).to eql(previous_application_form)
      expect(application_form.previous_application_form.subsequent_application_form).to eql(application_form)
    end
  end

  describe '#choices_left_to_make' do
    it 'returns the number of choices that an candidate can make in the first instance' do
      application_form = create(:application_form)

      expect(application_form.reload.choices_left_to_make).to be(3)

      create(:application_choice, application_form: application_form)

      expect(application_form.reload.choices_left_to_make).to be(2)

      create(:application_choice, application_form: application_form)

      expect(application_form.reload.choices_left_to_make).to be(1)

      create(:application_choice, application_form: application_form)

      expect(application_form.reload.choices_left_to_make).to be(0)
    end

    it 'returns the number of choices that an candidate can make in "Apply 2"' do
      application_form = create(:application_form, phase: 'apply_2')

      expect(application_form.reload.choices_left_to_make).to be(1)

      create(:application_choice, application_form: application_form)

      expect(application_form.reload.choices_left_to_make).to be(0)
    end
  end

  describe 'auditing', with_audited: true do
    it 'records an audit entry when creating a new ApplicationForm' do
      application_form = create :application_form
      expect(application_form.audits.count).to eq 1
    end

    it 'can view audit records for ApplicationForm and its associated ApplicationChoices' do
      application_form = create(:completed_application_form, application_choices_count: 1)

      expect {
        application_form.application_choices.first.update!(rejection_reason: 'rejected')
      }.to change { application_form.own_and_associated_audits.count }.by(1)
    end
  end

  describe '#science_gcse_needed?' do
    context 'when a candidate has no course choices' do
      it 'returns false' do
        application_form = build_stubbed(:application_form)

        expect(application_form.science_gcse_needed?).to eq(false)
      end
    end

    context 'when a candidate has a course choice that is primary' do
      it 'returns true' do
        application_form = application_form_with_course_option_for_provider_with(level: 'primary')

        expect(application_form.science_gcse_needed?).to eq(true)
      end
    end

    context 'when a candidate has a course choice that is secondary' do
      it 'returns false' do
        application_form = application_form_with_course_option_for_provider_with(level: 'secondary')

        expect(application_form.science_gcse_needed?).to eq(false)
      end
    end

    context 'when a candidate has a course choice that is further education' do
      it 'returns false' do
        application_form = application_form_with_course_option_for_provider_with(level: 'further_education')

        expect(application_form.science_gcse_needed?).to eq(false)
      end
    end

    def application_form_with_course_option_for_provider_with(level:)
      provider = build(:provider)
      course = create(:course, level: level, provider: provider)
      site = create(:site, provider: provider)
      course_option = create(:course_option, course: course, site: site)
      application_form = create(:application_form)

      create(
        :application_choice,
        application_form: application_form,
        course_option: course_option,
      )

      application_form
    end
  end

  describe '#blank_application?' do
    context 'when a candidate has not made any alterations to their applicaiton' do
      it 'returns true' do
        application_form = create(:application_form)
        expect(application_form.blank_application?).to be_truthy
      end
    end

    context 'when a candidate has amended their application' do
      it 'returns false' do
        application_form = create(:application_form)
        create(:application_work_experience, application_form: application_form)
        expect(application_form.blank_application?).to be_falsey
      end
    end
  end

  describe '#ended_without_success?' do
    context 'with one rejected application' do
      it 'returns true' do
        application_form = described_class.new
        application_form.application_choices.build status: 'rejected'
        expect(application_form.ended_without_success?).to be true
      end
    end

    context 'with one offered application' do
      it 'returns false' do
        application_form = described_class.new
        application_form.application_choices.build status: 'offer'
        expect(application_form.ended_without_success?).to be false
      end
    end

    context 'with one rejected and one in progress application' do
      it 'returns false' do
        application_form = described_class.new
        application_form.application_choices.build status: 'rejected'
        application_form.application_choices.build status: 'awaiting_provider_decision'
        expect(application_form.ended_without_success?).to be false
      end
    end

    context 'with one rejected and one withdrawn application' do
      it 'returns true' do
        application_form = described_class.new
        application_form.application_choices.build status: 'rejected'
        application_form.application_choices.build status: 'withdrawn'
        expect(application_form.ended_without_success?).to be true
      end
    end
  end

  describe '#can_add_reference?' do
    it 'returns true if there are fewer than 2 references' do
      application_reference = build :reference
      application_form = build :application_form, application_references: [application_reference]
      expect(application_form.can_add_reference?).to be true
    end

    it 'returns false if there are already 2 references' do
      application_reference1 = build :reference
      application_reference2 = build :reference
      application_form = build(
        :application_form,
        application_references: [application_reference1, application_reference2],
      )
      expect(application_form.can_add_reference?).to be false
    end
  end

  describe '#too_many_complete_references?' do
    it 'returns true if there are more than 2 references' do
      application_form = create :application_form
      references = []
      3.times { references << create(:reference, :feedback_provided) }
      application_form.application_references = references

      expect(application_form.too_many_complete_references?).to be true
    end

    it 'returns false if there are 2 or fewer references' do
      application_form = create :application_form
      expect(application_form.too_many_complete_references?).to be false
      application_form.application_references << create(:reference)
      expect(application_form.too_many_complete_references?).to be false
      application_form.application_references << create(:reference)
      expect(application_form.too_many_complete_references?).to be false
    end
  end

  describe '#equality_and_diversity_answers_provided?' do
    context 'when minimal expected attributes are present' do
      it 'is true' do
        application_form = build(:completed_application_form, :with_equality_and_diversity_data)
        expect(application_form.equality_and_diversity_answers_provided?).to be true
      end
    end

    context 'when minimal expected attributes are not present' do
      it 'is false' do
        application_form = build(:completed_application_form)
        application_form.equality_and_diversity = { 'sex' => 'male' }

        expect(application_form.equality_and_diversity_answers_provided?).to be false
      end
    end

    context 'when no attributes are present' do
      it 'is false' do
        application_form = build(:completed_application_form)
        application_form.equality_and_diversity = nil

        expect(application_form.equality_and_diversity_answers_provided?).to be false
      end
    end
  end

  describe '#english_speaking_nationality?' do
    context 'when any applicant nationality is identified as "English-speaking"' do
      let(:nationality_permutations) do
        [
          { first_nationality: 'British', second_nationality: 'Pakistani' },
          { first_nationality: 'Pakistani', second_nationality: 'British' },
          { first_nationality: 'British', second_nationality: nil },
          { first_nationality: 'Irish', second_nationality: 'Pakistani' },
          { first_nationality: 'Pakistani', second_nationality: 'Irish' },
          { first_nationality: 'Irish', second_nationality: nil },
          { first_nationality: 'Iranian', second_nationality: 'Pakistani', third_nationality: 'Irish' },
        ]
      end

      it 'returns true' do
        nationality_permutations.each do |permutation|
          application_form = build(:application_form, permutation)
          expect(application_form.english_speaking_nationality?).to eq true
        end
      end
    end

    context 'when no applicant nationality is identified as "English-speaking"' do
      let(:nationality_permutations) do
        [
          { first_nationality: 'Pakistani', second_nationality: nil },
          { first_nationality: 'Chinese', second_nationality: 'Pakistani' },
          { first_nationality: 'Chinese', second_nationality: 'Pakistani', third_nationality: 'Jamaican' },
        ]
      end

      it 'return false' do
        nationality_permutations.each do |permutation|
          application_form = build(:application_form, permutation)
          expect(application_form.english_speaking_nationality?).to eq false
        end
      end
    end
  end

  describe '#nationalities' do
    it 'returns the candidates nationalities in an array' do
      application_form = build_stubbed(:application_form,
                                       first_nationality: 'British',
                                       second_nationality: 'Irish',
                                       third_nationality: 'Welsh',
                                       fourth_nationality: 'Northern Irish',
                                       fifth_nationality: nil)

      expect(application_form.nationalities).to match_array ['British', 'Irish', 'Welsh', 'Northern Irish']
    end
  end

  describe '#english_main_language' do
    context 'when fetch_database_value is set to true' do
      it 'returns whatever is in the database field' do
        [nil, true, false].each do |db_value|
          application_form = build(:application_form, english_main_language: db_value)
          expect(
            application_form.english_main_language(fetch_database_value: true),
          ).to eq db_value
        end
      end
    end

    context 'database value is nil' do
      let(:application_form) { build(:application_form, english_main_language: nil) }

      it 'returns false by default' do
        expect(application_form.english_main_language).to eq false
      end

      context 'when english_speaking_nationality? is true' do
        it 'returns true' do
          application_form.first_nationality = 'British'

          expect(application_form.english_main_language).to eq true
        end
      end

      context 'when the english_proficiency record declares that a qualification is not needed' do
        it 'returns true' do
          english_proficiency = build(:english_proficiency, :qualification_not_needed)
          application_form.english_proficiency = english_proficiency

          expect(application_form.english_main_language).to eq true
        end
      end
    end

    context 'database value is true' do
      let(:application_form) { build(:application_form, english_main_language: true) }

      it 'returns true' do
        expect(application_form.english_main_language).to eq true
      end
    end

    context 'database value is false' do
      let(:application_form) { build(:application_form, english_main_language: false) }

      it 'returns false' do
        expect(application_form.english_main_language).to eq false
      end
    end
  end

  describe '#efl_section_required?' do
    let(:application_with_english_speaking_nationality) do
      build_stubbed :application_form, first_nationality: 'British', second_nationality: 'French'
    end

    let(:application_with_no_english_speaking_nationalities) do
      build_stubbed :application_form, first_nationality: 'Jamaican', second_nationality: 'Chinese'
    end

    context 'at least one selected nationality is considered "English-speaking"' do
      let(:application_form) { application_with_english_speaking_nationality }

      it 'returns false' do
        expect(application_form.efl_section_required?).to be false
      end
    end

    context 'no "English-speaking" nationalities selected' do
      let(:application_form) { application_with_no_english_speaking_nationalities }

      it 'returns true' do
        expect(application_form.efl_section_required?).to be true
      end
    end

    context 'nationalities not selected' do
      let(:application_form) { build_stubbed :application_form }

      it 'returns false' do
        expect(application_form.efl_section_required?).to be false
      end
    end
  end

  describe '#all_applications_not_sent?' do
    let(:application_form) { build(:application_form) }

    it 'returns true if all application choices are in the application_not_sent or withdrawn state' do
      create(:application_choice, :application_not_sent, application_form: application_form)
      create(:application_choice, :withdrawn, application_form: application_form)

      expect(application_form.all_applications_not_sent?).to eq true
    end

    it 'returns false if application choices are in any other state' do
      create(:application_choice, :withdrawn, application_form: application_form)

      expect(application_form.all_applications_not_sent?).to eq false
    end
  end

  describe '#has_rejection_reason?' do
    let(:application_form) { create(:completed_application_form) }

    it 'returns true if any of the choices are rejected' do
      create(:application_choice, :with_rejection, application_form: application_form)

      expect(application_form.has_rejection_reason?).to eq true
    end
  end

  describe '#references_did_not_come_back_in_time?' do
    let(:application_form) { create(:completed_application_form) }

    it 'returns true if all references were cancelled at end of cycle' do
      create(:reference, application_form: application_form, feedback_status: :cancelled_at_end_of_cycle)

      expect(application_form.references_did_not_come_back_in_time?).to eq true
    end
  end

  describe '#full_address' do
    it 'returns the candidate address and postcode for UK addresses' do
      application_form = create(
        :completed_application_form,
        address_line1: 'Flat 4 Prospect House',
        address_line2: 'Technique Street',
        address_line3: 'West Glamorgan',
        postcode: 'NW1 8TQ',
      )

      expect(application_form.full_address).to eq [
        'Flat 4 Prospect House',
        'Technique Street',
        'West Glamorgan',
        'NW1 8TQ',
      ]
    end

    it 'renders the candidate address for international addresses' do
      application_form = build_stubbed(
        :completed_application_form,
        :international_address,
        address_line1: 'Beverley Hills',
        address_line2: nil,
        address_line3: '90210',
        postcode: nil,
        country: 'US',
      )

      expect(application_form.full_address).to eq ['Beverley Hills', '90210', 'United States']
    end
  end

  describe '#domicile' do
    it 'calls #hesa_code_for_country for international addresses' do
      application_form = build_stubbed(:completed_application_form, :international_address)
      allow(DomicileResolver).to receive(:hesa_code_for_country)
                                 .with(application_form.country).and_return(':)')

      expect(application_form.domicile).to eq(':)')
    end

    it 'calls #hesa_code_for_postcode for UK addresses' do
      application_form = create(:completed_application_form)
      allow(DomicileResolver).to receive(:hesa_code_for_postcode)
                                 .with(application_form.postcode).and_return(':)')

      expect(application_form.domicile).to eq(':)')
    end
  end

  describe '#all_provider_decisions_made?' do
    it 'returns false if the application choices are in awaiting provider decision state' do
      application_choice = create :submitted_application_choice
      application_form = create(:completed_application_form, application_choices: [application_choice])
      expect(application_form.all_provider_decisions_made?).to eq(false)
    end

    it 'returns true if the application choices are not in awaiting provider decision state' do
      application_choice = create(:application_choice, :with_offer)
      application_form = create(:completed_application_form, application_choices: [application_choice])
      expect(application_form.all_provider_decisions_made?).to eq(true)
    end
  end
end
