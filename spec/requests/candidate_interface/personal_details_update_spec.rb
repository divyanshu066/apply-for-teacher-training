require 'rails_helper'

RSpec.describe 'Candidate interface - personal details', type: :request do
  def create_candidate(magic_link_token)
    create(
      :candidate,
      magic_link_token: magic_link_token.encrypted,
      magic_link_token_sent_at: Time.now,
    )
  end

  def valid_attributes
    {
      first_name: 'Bob',
      last_name: 'Smith',
      english_main_language: 'yes',
      first_nationality: 'British',
      'date_of_birth(1i)': '2000',
      'date_of_birth(2i)': '1',
      'date_of_birth(3i)': '1',
    }
  end

  it 'updates the personal details on the application form' do
    magic_link_token = MagicLinkToken.new
    candidate = create_candidate(magic_link_token)

    expect {
      post candidate_interface_personal_details_update_url(
        token: magic_link_token.raw,
        candidate_interface_personal_details_form: valid_attributes,
      )
    }.to(change { candidate.current_application.first_name })

    expect(response).to have_http_status(200)
    expect(candidate.current_application.first_name).to eq 'Bob'
    expect(candidate.current_application.last_name).to eq 'Smith'
    expect(candidate.current_application.english_main_language).to be true
    expect(candidate.current_application.first_nationality).to eq 'British'
    expect(candidate.current_application.date_of_birth).to eq Date.new(2000, 1, 1)
  end

  it 'creates audit records attributed to the authenticated candidate' do
    magic_link_token = MagicLinkToken.new
    candidate = create_candidate(magic_link_token)

    expect {
      post candidate_interface_personal_details_update_url(
        token: magic_link_token.raw,
        candidate_interface_personal_details_form: valid_attributes,
      )
    }.to(change { candidate.current_application.audits.count })

    expect(candidate.current_application.audits.last.user).to eq candidate
  end
end
