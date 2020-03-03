require 'rails_helper'

RSpec.describe SetupQAEnvironment do
  it 'blows up in the wrong environment' do
    ClimateControl.modify HOSTING_ENVIRONMENT_NAME: 'production' do
      expect { SetupQAEnvironment.call }.to raise_error('You can’t do this anywhere but QA or development!')
    end
  end

  describe 'fetching UIDs from a URL' do
    let(:uids_file_contents) { "UID1\nUID2" }
    let(:uids_request_http_status) { 200 }

    around do |spec|
      create(:application_choice)
      stub_request(:get, 'http://example.com/uids.txt').to_return(status: uids_request_http_status, body: uids_file_contents)

      ClimateControl.modify(QA_USER_UIDS_URL: 'http://example.com/uids.txt', HOSTING_ENVIRONMENT_NAME: 'qa') do
        spec.run
      end
    end

    it 'creates support users with the correct uids' do
      SetupQAEnvironment.call
      expect(SupportUser.pluck(:dfe_sign_in_uid)).to match_array %w[UID1 UID2]
    end

    it 'creates provider users with the correct uids' do
      SetupQAEnvironment.call
      expect(ProviderUser.pluck(:dfe_sign_in_uid)).to match_array %w[UID1 UID2]
    end

    context 'when the URL contains no data' do
      let(:uids_file_contents) { '' }

      it 'raises a sensible error' do
        expect { SetupQAEnvironment.call }.to raise_error('No UIDs found in the UIDs file at http://example.com/uids.txt')
      end
    end

    context 'when the URL returns a non-200 status code' do
      let(:uids_request_http_status) { 404 }

      it 'raises a sensible error' do
        expect { SetupQAEnvironment.call }.to raise_error('Could not load the UIDs file at http://example.com/uids.txt. Received status code 404')
      end
    end
  end
end
