require 'rails_helper'

RSpec.describe ProviderUser, type: :model do
  describe '#downcase_email_address' do
    it 'saves email_address in lower case' do
      provider_user = create :provider_user, email_address: 'Bob.Roberts@example.com'
      expect(provider_user.reload.email_address).to eq 'bob.roberts@example.com'
    end
  end

  describe '.onboard!' do
    it 'sets the DfE Sign-in ID on an existing user' do
      provider_user = create :provider_user, dfe_sign_in_uid: nil
      dsi_user = DfESignInUser.new(
        email_address: provider_user.email_address,
        dfe_sign_in_uid: 'ABC123',
        first_name: nil,
        last_name: nil,
      )
      ProviderUser.onboard!(dsi_user)
      expect(provider_user.reload.dfe_sign_in_uid).to eq 'ABC123'
    end

    it 'sets the DfE Sign-in ID on an existing user with a mixed case DfE Sign-in email' do
      provider_user = create :provider_user, dfe_sign_in_uid: nil, email_address: 'bob@example.com'
      dsi_user = DfESignInUser.new(
        email_address: 'BoB@example.com',
        dfe_sign_in_uid: 'ABC123',
        first_name: nil,
        last_name: nil,
      )
      ProviderUser.onboard!(dsi_user)
      expect(provider_user.reload.dfe_sign_in_uid).to eq 'ABC123'
    end
  end

  describe '#full_name' do
    it 'concatenates the first and last names of the user' do
      provider_user = build :provider_user
      expect(provider_user.full_name).to eq "#{provider_user.first_name} #{provider_user.last_name}"
    end

    it 'is nil if the first and last names are nil' do
      provider_user = build(:provider_user, first_name: nil, last_name: nil)
      expect(provider_user.full_name).to be_nil
    end
  end

  describe 'auditing', with_audited: true do
    it 'records an audit entry when creating and updating a new ProviderUser' do
      provider_user = create :provider_user, first_name: 'Bob'
      expect(provider_user.audits.count).to eq 1
      provider_user.update(first_name: 'Alice')
      expect(provider_user.audits.count).to eq 2
    end

    it 'records an audit entry when creating adding an existing ProviderUser to a Provider' do
      provider_user = create :provider_user, first_name: 'Bob'
      provider = create :provider
      expect(provider_user.audits.count).to eq 1
      provider_user.providers << provider
      expect(provider_user.associated_audits.count).to eq 1
      expect(provider_user.associated_audits.first.audited_changes['provider_id']).to eq provider.id
    end
  end

  describe 'can_manage_users?' do
    let(:provider_user) { create :provider_user, :with_provider }

    it 'is false for users without the manage users permission' do
      expect(provider_user.can_manage_users?).to be false
    end

    it 'is true for users with the manage users permission' do
      provider_user.provider_permissions.first.update(manage_users: true)

      expect(provider_user.can_manage_users?).to be true
    end
  end

  describe '.visible_to' do
    it 'returns provider users with access to the same providers as the passed user' do
      provider = create(:provider)
      user_a = create(:provider_user, providers: [provider])
      user_b = create(:provider_user, providers: [provider])

      expect(ProviderUser.visible_to(user_a)).to include(user_b)
    end
  end
end
