module ProviderInterface
  class EditProviderUserForm
    include ActiveModel::Model

    attr_accessor :provider_user
    attr_accessor :editing_user

    # these are all the permissions to make available in the form
    def possible_permissions
      provider_ids = editing_user.provider_permissions.manage_users.pluck(:provider_id)
      provider_ids.map do |id|
        ProviderPermissions.find_or_initialize_by(
          provider_id: id,
          provider_user_id: provider_user.id,
        )
      end
    end

    def forms_for_possible_permissions
      possible_permissions.map { |p| ProviderPermissionsForm.new(active: p.persisted?, provider_permission: p) }
    end

    def save!
      # validate first that the new permissions are all legit
      # nuke all the old permissions and create a fresh set
      possible_permissions.select(&:persisted?).map(&:destroy!)
      @provider_permissions.map(&:save!)
    end

    # these are the new permissions we will save.
    # this method accepts serialized ProviderPermissionsForms
    # in the form { provider_id => form_attrs }
    def provider_permissions=(attributes)
      forms = attributes.map { |_, attrs| ProviderPermissionsForm.new(attrs) }.select(&:active)
      @provider_permissions = forms.map do |form|
        permission = ProviderPermissions.new(form.provider_permission)
        permission.provider_user_id = provider_user.id
        permission
        # handle assignment of manage_users etc in here too
      end
    end
  end

  class ProviderPermissionsForm
    include ActiveModel::Model

    attr_accessor :active
    attr_accessor :provider_permission

    delegate :provider, to: :provider_permission

    # required for fields_for
    def id
      provider.id
    end
  end
end
