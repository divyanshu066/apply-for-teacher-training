class PermissionsList < ViewComponent::Base
  attr_reader :user_is_viewing_their_own_permissions

  def initialize(permission_model, user_is_viewing_their_own_permissions: false)
    @permission_model = permission_model
    @user_is_viewing_their_own_permissions = user_is_viewing_their_own_permissions
  end

  def training_providers_that_can(permission)
    permissions_as_ratifying_provider.map { |permission_relationship|
      permission_relationship.training_provider if permission_relationship.send("training_provider_can_#{permission}?")
    }.compact
  end

  def ratifying_providers_that_can(permission)
    permissions_as_training_provider.map { |permission_relationship|
      permission_relationship.ratifying_provider if permission_relationship.send("ratifying_provider_can_#{permission}?")
    }.compact
  end

private

  def permissions_as_ratifying_provider
    @permissions_as_ratifying_provider ||= ProviderRelationshipPermissions.where(ratifying_provider_id: @permission_model.provider.id)
  end

  def permissions_as_training_provider
    @permissions_as_training_provider ||= ProviderRelationshipPermissions.where(training_provider_id: @permission_model.provider.id)
  end
end
