require 'rails_helper'

RSpec.describe 'GET apply-for-teacher-training.education.gov.uk redirects to apply-for-teacher-training.service.gov.uk', type: :request do
  it 'redirects to qa.apply-for-teacher-training.service.gov.uk' do
    get 'https://qa.apply-for-teacher-training.education.gov.uk'
    expect(response.location).to include('https://qa.apply-for-teacher-training.service.gov.uk')
  end
end
