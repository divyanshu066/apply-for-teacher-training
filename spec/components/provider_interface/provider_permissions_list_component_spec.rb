require 'rails_helper'

RSpec.describe ProviderInterface::ProviderPermissionsListComponent do
  before do
    @provider = create(:provider, name: 'Hoth University')
    @provider_user = create(:provider_user, providers: [@provider])
  end

  it 'renders no permissions if a provider has no permissions' do
    @provider_user.provider_permissions.find_by(provider: @provider).update(manage_users: false)

    result = render_inline described_class.new(provider_user: @provider_user, permissions: @provider_user.provider_permissions)

    expect(result.text).to include('No permissions')
  end

  it 'renders the correct permissions for a provider it has permissions with' do
    @provider_user.provider_permissions.find_by(provider: @provider).update(manage_users: true)

    result = render_inline described_class.new(provider_user: @provider_user, permissions: @provider_user.provider_permissions)

    expect(result.text).to include('Manage users')
  end

  context 'when a provider user has more than one provider' do
    before do
      @provider = create(:provider, name: 'Naboo University')
      @provider_two = create(:provider, name: 'Hoth University')
      @provider_user = create(:provider_user, providers: [@provider, @provider_two])

      @provider_user.provider_permissions.find_by(provider: @provider).update(manage_users: false)
      @provider_user.provider_permissions.find_by(provider: @provider_two).update(manage_users: true)
    end

    it 'renders the correct permissions for the provider it has permissions with' do
      result = render_inline described_class.new(provider_user: @provider_user, permissions: @provider_user.provider_permissions)

      expect(result.text).to include('Naboo University')
      expect(result.text).to include('Manage users')
    end

    it 'renders "No permissions" for the provider it has no permissions with' do
      result = render_inline described_class.new(provider_user: @provider_user, permissions: @provider_user.provider_permissions)

      expect(result.text).to include('Hoth University')
      expect(result.text).to include('No permissions')
    end
  end
end
