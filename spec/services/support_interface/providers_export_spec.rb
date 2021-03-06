require 'rails_helper'

RSpec.describe SupportInterface::ProvidersExport, with_audited: true do
  describe '#providers' do
    it 'returns synced providers and the date they signed the data sharing agreement' do
      create(:provider, sync_courses: false)
      provider_without_signed_dsa = create(:provider, sync_courses: true, name: 'B', latitude: 51.498161, longitude: 0.129900)
      create(:site, latitude: 51.482578, longitude: -0.007659, provider: provider_without_signed_dsa)
      create(:site, latitude: 52.246868, longitude: 0.711190, provider: provider_without_signed_dsa)

      provider_with_signed_dsa = nil
      Timecop.freeze(Time.zone.local(2019, 10, 1, 12, 0, 0)) do
        provider_with_signed_dsa = create(
          :provider,
          :with_signed_agreement,
          sync_courses: true,
          name: 'A',
        )
      end

      providers = described_class.new.providers
      expect(providers.size).to eq(2)

      expect(providers).to contain_exactly(
        {
          'name' => provider_with_signed_dsa.name,
          'code' => provider_with_signed_dsa.code,
          'agreement_accepted_at' => Time.zone.local(2019, 10, 1, 12, 0, 0),
          'Average distance to site' => '',
        },
        {
          'name' => provider_without_signed_dsa.name,
          'code' => provider_without_signed_dsa.code,
          'agreement_accepted_at' => nil,
          'Average distance to site' => '31.7',
        },
      )
    end
  end
end
