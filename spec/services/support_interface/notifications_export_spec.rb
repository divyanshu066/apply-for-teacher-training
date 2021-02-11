require 'rails_helper'

RSpec.describe SupportInterface::NotificationsExport do
  describe '#data_for_export' do
    let!(:application_choice) { create(:application_choice, :awaiting_provider_decision, course_option: course_option) }
    let!(:decided_application_choice) { create(:application_choice, :with_offer, course_option: course_option) }
    let!(:rbd_application_choice) { create(:application_choice, :with_rejection_by_default, course_option: course_option) }
    let(:course_option) { create(:course_option, course: course) }
    let(:provider) { create(:provider) }
    let(:course) { create(:course, provider: provider) }

    it 'returns the correct count for user notification related events' do
      create(:provider_user, :with_make_decisions, providers: [provider], send_notifications: false)
      create(:provider_user, :with_make_decisions, providers: [provider], send_notifications: true)
      create(:provider_user, providers: [provider], send_notifications: true)
      expect(described_class.new.data_for_export).to match_array([
       {
         'Provider Code' => provider.code,
         'Provider' => provider.name,
         'No. Applications Received' => 3,
         'No. Applications awaiting decisions' => 1,
         'No. applications receiving decisions' => 1,
         "No. applications RBD'd" => 1,
         'No. provider users' => 3,
         'No. users with make_decisions' => 2,
         'No. of users with make_decisions and notifications disabled' => 1,
         'No. of users with make_decisions and notifications enabled' => 1,
       },
      ])
    end
  end
end
