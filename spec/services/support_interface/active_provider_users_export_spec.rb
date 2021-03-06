require 'rails_helper'

RSpec.describe SupportInterface::ActiveProviderUsersExport do
  describe '#data_for_export' do
    it 'returns provider_users who have have signed in at least once' do
      Timecop.freeze(2020, 5, 1, 12, 0, 0) do
        provider1 = create(:provider)
        provider2 = create(:provider)
        provider_user1 = create(:provider_user, providers: [provider1], last_signed_in_at: 5.days.ago)
        provider_user2 = create(:provider_user, providers: [provider2], last_signed_in_at: 5.days.ago)
        provider_user3 = create(:provider_user, providers: [provider1, provider2], last_signed_in_at: 3.days.ago)
        create(:provider_user, providers: [provider1])

        expect(described_class.new.data_for_export).to match_array([
          {
            name: provider_user1.full_name,
            email_address: provider_user1.email_address,
            providers: provider1.name,
            last_signed_in_at: 5.days.ago,
          },
          {
            name: provider_user2.full_name,
            email_address: provider_user2.email_address,
            providers: provider2.name,
            last_signed_in_at: 5.days.ago,
          },
          {
            name: provider_user3.full_name,
            email_address: provider_user3.email_address,
            providers: "#{provider1.name}, #{provider2.name}",
            last_signed_in_at: 3.days.ago,
          },
        ])
      end
    end
  end
end
