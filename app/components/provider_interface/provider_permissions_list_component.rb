module ProviderInterface
  class ProviderPermissionsListComponent < ActionView::Component::Base
    include ViewHelper
    attr_reader :provider_user, :permissions

    def initialize(provider_user:, permissions:)
      @provider_user = provider_user
      @permissions = permissions
    end

  end
end
