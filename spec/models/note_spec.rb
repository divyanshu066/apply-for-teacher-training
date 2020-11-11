require 'rails_helper'

RSpec.describe Note do
  it 'changes updated_at on the associated ApplicationChoice' do
    choice = create(:application_choice)

    expect {
      create(:note, application_choice: choice)
    }.to(change { choice.updated_at })
  end

  describe '.visible_to' do
    it 'includes notes visible to this user' do
    end
  end
end
