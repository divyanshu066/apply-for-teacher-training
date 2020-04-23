class ProviderPermissionsOptions
  include ActiveModel::Model

  VALID_PERMISSIONS = %i[manage_users].freeze

  attr_accessor(*VALID_PERMISSIONS)

  def self.valid?(permission_name)
    VALID_PERMISSIONS.include?(permission_name.to_sym)
  end

  def self.for_provider_user(provider_user)
    permissions_attributes = {}
    scope = ProviderPermissions.where(provider_user: provider_user)

    VALID_PERMISSIONS.each do |permission_name|
      provider_ids = scope.where(permission_name => true).pluck(:provider_id)
      permissions_attributes[permission_name] = provider_ids if provider_ids.any?
    end

    new(permissions_attributes)
  end
end
