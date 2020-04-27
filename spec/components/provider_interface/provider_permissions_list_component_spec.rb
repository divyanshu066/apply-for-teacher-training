require 'rails_helper'

RSpec.describe ProviderInterface::ProviderPermissionsListComponent do
  let(:provider_user) { build_stubbed(:provider_user) }
  let(:permissions) { ProviderPermissionsOptions.new(manage_users: [1, 3]) }
  let(:providers) {
    [
      build_stubbed(:provider, id: 1),
      build_stubbed(:provider, id: 2),
      build_stubbed(:provider, id: 3),
    ]
  }

  it 'renders the correct permissions per provider' do
    allow(provider_user).to receive(:providers).and_return(providers)

    result = render_inline(
      described_class.new(
        provider_user: provider_user,
        permissions: permissions,
      ),
    )

    expect(result.text).to include(providers.first.name)
    expect(result.css('#provider-1-enabled-permissions').text).to include('Manage users')
    expect(result.text).to include(providers.last.name)
    expect(result.css('#provider-3-enabled-permissions').text).to include('Manage users')

    expect(result.text).not_to include(providers.second.name)
    expect(result.to_html).not_to include('#provider-2-enabled-permissions')
  end
end
