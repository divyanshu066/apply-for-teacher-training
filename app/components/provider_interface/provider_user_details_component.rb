module ProviderInterface
  class ProviderUserDetailsComponent < ViewComponent::Base
    include ViewHelper
    attr_reader :header

    def initialize(provider_user:, permissions:)
      @provider_user = provider_user
      @header = provider_user.full_name
      @permissions = permissions
    end

    def rows
      [
        { key: 'Name', value: @provider_user.full_name },
        { key: 'Email', value: @provider_user.email_address },
        permissions_row,
      ].compact
    end

    def permissions_row
      {
        key: 'Permissions',
        value: render(
          ProviderInterface::ProviderPermissionsListComponent.new(
            permissions: @permissions,
          ),
        ),
        change_path: provider_interface_provider_user_edit_providers_path(@provider_user),
        action: 'Change',
      }
    end
  end
end
