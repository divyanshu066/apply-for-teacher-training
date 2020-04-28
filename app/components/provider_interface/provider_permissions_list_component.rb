module ProviderInterface
  class ProviderPermissionsListComponent < ViewComponent::Base
    include ViewHelper
    attr_reader :permissions

    def initialize(permissions:)
      @permissions = permissions
    end
  end
end
