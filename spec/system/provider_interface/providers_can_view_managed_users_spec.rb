require 'rails_helper'

RSpec.feature 'Provider invites a new provider user' do
  include DfESignInHelpers
  include DsiAPIHelper

  scenario 'Provider use can see their individual users permissions' do
    given_i_am_a_provider_user_with_dfe_sign_in
    and_the_provider_add_provider_users_feature_is_enabled
    and_i_can_manage_applications_for_two_providers
    and_i_can_manage_users_for_a_provider
    and_i_sign_in_to_the_provider_interface
    and_i_have_some_providers_that_can_managed_users

    when_i_click_on_the_users_link
    and_i_click_on_a_users_name
    the_users_details_should_be_visible
  end


  def and_i_have_some_providers_that_can_managed_users
    @provider_user = ProviderUser.find_by(dfe_sign_in_uid: 'DFE_SIGN_IN_UID')

    @provider = Provider.find_by(code: 'ABC')
    @another_provider = Provider.find_by(code: 'DEF')

    @provider_user.provider_permissions.find_by(provider: @provider).update(manage_users: true)
    @provider_user.provider_permissions.find_by(provider: @another_provider).update(manage_users: true)

    ProviderUser.find_by(id: @provider_user.provider_permissions.find_by(provider: @provider).provider_user_id)
      .update(first_name: 'Joe', last_name: 'Blogs')
  end

  def given_i_am_a_provider_user_with_dfe_sign_in
    provider_exists_in_dfe_sign_in
  end

  def and_the_provider_add_provider_users_feature_is_enabled
    FeatureFlag.activate('provider_add_provider_users')
  end

  def and_i_can_manage_applications_for_two_providers
    provider_user_exists_in_apply_database
    @provider_user = ProviderUser.find_by(dfe_sign_in_uid: 'DFE_SIGN_IN_UID')
    @provider = Provider.find_by(code: 'ABC')
    @another_provider = Provider.find_by(code: 'DEF')
  end

  def and_i_can_manage_users_for_a_provider
    @provider_user.provider_permissions.find_by(provider: @provider).update(manage_users: true)
  end

  def when_i_click_on_the_users_link
    click_on('Users')
  end

  def and_i_click_on_a_users_name
    click_link('Joe Blogs', match: :first)
  end

  def the_users_details_should_be_visible
    expect(page).to have_content('Joe Blogs')
    expect(page).to have_content('Permissions')
    expect(page).to have_content('Manage users')
    expect(page).to have_content('Example Provider')
    expect(page).to have_content('Another Provider')
  end
end
