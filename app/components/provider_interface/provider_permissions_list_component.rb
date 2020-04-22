module ProviderInterface
  class ProviderPermissionsListComponent < ActionView::Component::Base
    include ViewHelper
    attr_reader :provider_user

    def initialize(provider_user:)
      @provider_user = provider_user
    end

  end
end
