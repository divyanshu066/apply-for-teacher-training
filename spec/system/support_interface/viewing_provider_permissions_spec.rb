require 'rails_helper'

RSpec.feature 'Viewing provider-provider permissions via support' do
  include DfESignInHelpers

  scenario 'Support user views provider permissions via users page' do
    given_i_am_a_support_user
    and_there_are_two_providers_in_a_partnership

    when_i_visit_the_training_provider
    and_click_users
    then_i_should_see_the_training_provider_permissions_diagram

    when_i_visit_the_ratifying_provider
    and_click_users
    then_i_should_see_the_ratifying_provider_permissions_diagram
  end

  def given_i_am_a_support_user
    sign_in_as_support_user
  end

  def and_there_are_two_providers_in_a_partnership
    training = create(:provider, sync_courses: true, name: 'Numan College')
    ratifying = create(:provider, sync_courses: true, name: 'Oldman University')

    create(
      :provider_relationship_permissions,
      training_provider: training,
      ratifying_provider: ratifying,
      ratifying_provider_can_make_decisions: true,
      ratifying_provider_can_view_safeguarding_information: false,
      ratifying_provider_can_view_diversity_information: true,
      training_provider_can_make_decisions: false,
      training_provider_can_view_safeguarding_information: true,
      training_provider_can_view_diversity_information: false,
    )
  end

  def when_i_visit_the_training_provider
    click_on 'Providers'
    click_on 'Numan College'
  end

  def and_click_users
    click_on 'Users'
  end

  def then_i_should_see_the_training_provider_permissions_diagram
    expect(page).to have_content 'can ✅ view safeguarding ❌ view diversity ❌ make decisions for courses ratified by'
  end

  def when_i_visit_the_ratifying_provider
    visit '/support'
    click_on 'Providers'
    click_on 'Oldman University'
  end

  def then_i_should_see_the_ratifying_provider_permissions_diagram
    expect(page).to have_content 'can ❌ view safeguarding ✅ view diversity ✅ make decisions for courses run by'
  end
end