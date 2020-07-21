require 'rails_helper'

RSpec.describe ProviderRelationshipPermissions do
  describe '.permissions_fields' do
    subject(:permissions_fields) { described_class.permissions_fields }

    it 'returns all permissions fields' do
      expect(permissions_fields).to eq(%w[
        ratifying_provider_can_make_decisions
        training_provider_can_make_decisions
        ratifying_provider_can_view_safeguarding_information
        training_provider_can_view_safeguarding_information
      ])
    end
  end
end
