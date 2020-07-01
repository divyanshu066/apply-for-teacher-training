require 'rails_helper'

RSpec.describe ProviderInterface::ApplicationCardComponent do
  include CourseOptionHelpers

  let(:current_provider) do
    create(:provider,
           :with_signed_agreement,
           code: 'ABC',
           name: 'Hoth Teacher Training')
  end

  let(:accredited_provider) do
    create(:provider,
           :with_signed_agreement,
           code: 'XYZ',
           name: 'Yavin University')
  end

  let(:course_option) do
    course_option_for_provider(provider: current_provider,
                               course: create(:course,
                                              name: 'Alchemy',
                                              provider: current_provider,
                                              accredited_provider: accredited_provider))
  end

  let(:application_choice) do
    create(:application_choice,
           :awaiting_provider_decision,
           course_option: course_option,
           status: 'withdrawn',
           application_form: create(:application_form,
                                    first_name: 'Jim',
                                    last_name: 'James'),
           site: create(:site, code: 'L123', name: 'Skywalker Training'),
           updated_at: Date.parse('25-03-2020'))
  end

  let(:note) do
    provider_user = current_provider.provider_users.first
    Note.new(
      provider_user: provider_user,
      subject: 'Needs review',
      message: 'Please review asap as the deadline is looming.',
    )
  end

  let(:result) { render_inline described_class.new(application_choice: application_choice) }

  let(:card) { result.css('.app-application-card').to_html }

  describe 'rendering' do
    it 'renders the name of the candidate' do
      expect(card).to include('Jim James')
    end

    it 'renders the name of education provider' do
      expect(card).to include('Hoth Teacher Training')
    end

    it 'renders the name of the course' do
      expect(card).to include('Alchemy')
    end

    it 'renders the name of the accredited provider' do
      expect(card).to include('Yavin University')
    end

    it 'renders the status of the application' do
      expect(card).to include('Application withdrawn')
    end

    it 'renders the subject of the most recent note' do
      application_choice.notes << note
      expect(card).to include(note.subject)
    end

    it 'renders the last "changed at" date in the correct format' do
      expect(card).to include('Changed 25 March 2020 at 12:00am')
    end

    it 'renders the location of the course' do
      expect(card).to include('Skywalker Training (L123)')
    end

    context 'when there is no accredited provider' do
      let(:course_option_without_accredited_provider) do
        course_option_for_provider(provider: current_provider,
                                   course: create(:course,
                                                  name: 'Baking',
                                                  provider: current_provider))
      end

      let(:application_choice_without_accredited_provider) do
        create(:application_choice,
               :awaiting_provider_decision,
               course_option: course_option_without_accredited_provider,
               status: 'withdrawn', application_form: create(:application_form,
                                                             first_name: 'Jim',
                                                             last_name: 'James'),
               updated_at: Date.parse('25-03-2020'))
      end

      let(:result) { render_inline described_class.new(application_choice: application_choice_without_accredited_provider) }

      it 'renders the course provider name instead' do
        expect(result.css('.app-application-card__secondary').text).to include('Hoth Teacher Training')
      end
    end
  end

  describe '#contextual_date' do
    let(:reject_by_default_at) { DateTime.parse('2020-06-02T09:05:00+01:00') }
    let(:updated_at) { DateTime.parse('2020-06-02T09:05:00+01:00') }
    let(:application_choice) do
      build_stubbed(
        :application_choice,
        reject_by_default_at: reject_by_default_at,
        updated_at: updated_at,
        course_option: course_option,
      )
    end
    let(:sort_by) { 'Days left to respond' }

    subject(:component) { described_class.new(application_choice: application_choice, sort_by: sort_by) }

    context 'when not sorting by reject by default date' do
      let(:sort_by) { 'foo' }

      it 'presents the last changed date' do
        expect(component.contextual_date).to eq('Changed  2 June 2020 at  9:05am')
        expect(component.contextual_date).to eq('Changed  2 June 2020 at  9:05am')
      end
    end

    context 'when reject_by_default_at is nil' do
      let(:reject_by_default_at) { nil }

      it 'presents the last changed date' do
        expect(component.contextual_date).to eq('Changed  2 June 2020 at  9:05am')
      end
    end

    context 'when reject_by_default_at is in the past' do
      let(:reject_by_default_at) { 1.day.ago }

      it 'presents the last changed date' do
        expect(component.contextual_date).to eq('Changed  2 June 2020 at  9:05am')
      end
    end

    context 'when reject_by_default_at is less than a day away' do
      let(:reject_by_default_at) { 1.hour.from_now }

      it 'presents "Less than 1 day to respond"' do
        expect(described_class.new(application_choice: application_choice, sort_by: sort_by).contextual_date).to eq('Less than 1 day to respond')
      end
    end

    context 'when reject_by_default_at is a day away' do
      let(:reject_by_default_at) { 1.day.from_now }

      it 'presents "1 day to respond"' do
        expect(described_class.new(application_choice: application_choice, sort_by: sort_by).contextual_date).to eq('1 day to respond')
      end
    end

    context 'when reject_by_default_at is more than a day away' do
      let(:reject_by_default_at) { 5.days.from_now }

      it 'presents the number of days left to respond' do
        expect(described_class.new(application_choice: application_choice, sort_by: sort_by).contextual_date).to eq('5 days to respond')
      end
    end
  end
end
