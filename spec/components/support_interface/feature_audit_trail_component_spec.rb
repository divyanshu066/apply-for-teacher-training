require 'rails_helper'

RSpec.describe SupportInterface::FeatureAuditTrailComponent, with_audited: true do
  subject { described_class.new(feature: feature) }

  def bob_support_user
    @bob ||= create :support_user, email_address: 'bob@example.com'
  end

  def alice_support_user
    @alice ||= create :support_user, email_address: 'alice@example.com'
  end

  def render_result
    render_inline(subject)
  end

  context 'with a feature that was created with a false value' do
    def feature
      @feature ||= begin
        Timecop.freeze(Time.zone.local(2020, 5, 1, 12, 0, 0)) do
          Audited.audit_class.as_user(bob_support_user) do
            create(:feature)
          end
        end
      end
    end

    it 'renders the create audit entry' do
      expect(render_result.text).to include('1 May 2020 12:00 - Created Inactive by bob@example.com')
    end
  end

  context 'with a feature that was created with a true value and updated to false' do
    def feature
      @feature ||= begin
        Timecop.freeze(Time.zone.local(2020, 5, 1, 12, 0, 0)) do
          Audited.audit_class.as_user(bob_support_user) do
            create(:feature, active: true)
          end
        end
      end
      Timecop.freeze(Time.zone.local(2020, 5, 3, 15, 30, 0)) do
        Audited.audit_class.as_user(alice_support_user) do
          @feature.update!(active: false)
        end
      end
      @feature
    end

    it 'renders the create audit entry' do
      expect(render_result.text).to include('1 May 2020 12:00 - Created Active by bob@example.com')
    end

    it 'renders the update audit entry' do
      expect(render_result.text).to include('3 May 2020 15:30 - Changed to Inactive by alice@example.com')
    end
  end
end
