require 'rails_helper'

RSpec.feature 'See providers' do
  include FindAPIHelper

  scenario 'User visits providers page' do
    given_providers_are_configured_to_be_synced do
      given_i_am_a_support_user
      when_i_visit_the_providers_page
      and_i_click_the_sync_button
      then_requests_to_find_should_be_made
      and_i_should_see_the_updated_list_of_providers

      when_i_click_on_a_provider
      then_i_see_the_providers_courses_and_sites
    end
  end

  def given_i_am_a_support_user
    page.driver.browser.authorize('test', 'test')
  end

  def when_i_visit_the_providers_page
    visit support_interface_providers_path
  end

  def given_providers_are_configured_to_be_synced
    former_provider_list = Rails.application.config.providers_to_sync
    new_provider_list = { codes: %w[ABC DEF GHI] }

    Rails.application.config.providers_to_sync = new_provider_list
    yield
    Rails.application.config.providers_to_sync = former_provider_list
  end

  def then_i_should_see_the_providers
    expect(page).to have_content('Royal Academy of Dance')
    expect(page).not_to have_content('Gorse SCITT')
    expect(page).not_to have_content('Somerset SCITT Consortium')
  end

  def and_i_click_the_sync_button
    @request1 = stub_find_api_provider_200(
      provider_code: 'ABC',
      provider_name: 'Royal Academy of Dance',
      course_code: 'ABC-1',
      site_code: 'X',
    )

    @request2 = stub_find_api_provider_200(
      provider_code: 'DEF',
      provider_name: 'Gorse SCITT',
      course_code: 'DEF-1',
      site_code: 'Y',
    )

    @request3 = stub_find_api_provider_200(
      provider_code: 'GHI',
      provider_name: 'Somerset SCITT Consortium',
      course_code: 'GHI-1',
      site_code: 'C',
    )

    Sidekiq::Testing.inline! do
      click_button 'Sync Providers from Find'
    end
  end

  def then_requests_to_find_should_be_made
    expect(@request1).to have_been_made
    expect(@request2).to have_been_made
    expect(@request3).to have_been_made
  end

  def and_i_should_see_the_updated_list_of_providers
    expect(page).to have_content('Royal Academy of Dance')
    expect(page).to have_content('Gorse SCITT')
    expect(page).to have_content('Somerset SCITT Consortium')
  end

  def when_i_click_on_a_provider
    click_link 'Royal Academy of Dance'
  end

  def then_i_see_the_providers_courses_and_sites
    expect(page).to have_content 'ABC-1'
  end
end
