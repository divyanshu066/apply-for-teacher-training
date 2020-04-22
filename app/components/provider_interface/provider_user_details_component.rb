module ProviderInterface
  class ProviderUserDetailsComponent < ActionView::Component::Base
    include ViewHelper
    attr_reader :header

    def initialize(provider_user:, options: {})
      @provider_user = provider_user
      @header = provider_user.full_name
      @options = options
    end

    def rows
      [
        {
          key: 'Name',
          value: @provider_user.full_name,
        },
        {
          key: 'Email',
          value: @provider_user.email_address,
        },
        {
          key: 'Permissions',
          value: render(ProviderInterface::ProviderPermissionsListComponent.new(provider_user: @provider_user)),
          change_path: '#', action: 'Change'
        }
      ]
    end
  end
end
