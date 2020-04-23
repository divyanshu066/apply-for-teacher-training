require 'rails_helper'

RSpec.describe ProviderPermissionsOptions, type: :model do
  describe '.valid?' do
    context 'with a valid permission name' do
      it 'is true' do
        expect(described_class.valid?(:manage_users)).to be true
      end
    end

    context 'with an invalid permission name' do
      it 'is false' do
        expect(described_class.valid?(:not_a_permission)).to be false
      end
    end
  end

  describe '.for_provider_user' do
    let(:provider) { create(:provider) }
    let(:another_provider) { create(:provider) }
    let(:provider_user) { create(:provider_user, providers: [provider]) }

    before do
      provider_user.provider_permissions.first.update(manage_users: true)
      provider_user.providers << create(:provider)
    end

    it 'returns an instance based on permissions for the user' do
      result = described_class.for_provider_user(provider_user)

      expect(result).to be_a(described_class)
      expect(result.manage_users).to eq([provider.id])
    end
  end
end
