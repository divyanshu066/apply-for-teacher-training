require 'rails_helper'

RSpec.describe ProviderInterface::SortApplicationChoices do
  describe '#sort_order' do
    let(:sort_by) { nil }

    subject(:sort_order) { described_class.sort_order(sort_by) }

    it { is_expected.to eq({ updated_at: :desc }) }

    context 'when sort_by is RBD date' do
      let(:sort_by) { 'Days left to respond' }

      it 'returns reject_by_default_date and updated_at descending' do
        expect(sort_order).to eq(
          <<-ORDER_BY.strip_heredoc,
          (
            CASE
              WHEN (status='awaiting_provider_decision' AND (DATE(reject_by_default_at) > NOW())) THEN 1
              ELSE 0
            END
          ) DESC,
          reject_by_default_at ASC,
          application_choices.updated_at DESC
          ORDER_BY
        )
      end
    end

    context 'when sort param is Last changed' do
      let(:sort_by) { 'Last changed' }

      it { is_expected.to eq({ updated_at: :desc }) }
    end
  end

  describe '#sort_by_attribute' do
    let(:sort_by) { nil }

    subject(:sort_by_attribute) { described_class.sort_by_attribute(sort_by) }

    it { is_expected.to eq(:updated_at) }

    context 'when params contain a valid sort option' do
      let(:sort_by) { 'Days left to respond' }

      it { is_expected.to eq(:reject_by_default_at) }
    end
  end
end
