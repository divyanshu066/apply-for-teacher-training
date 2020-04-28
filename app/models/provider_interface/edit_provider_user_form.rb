module ProviderInterface
  class EditProviderUserForm
    include ActiveModel::Model

    attr_accessor :provider_user
    attr_accessor :editing_user

    def possible_permissions
      provider_ids = editing_user.provider_permissions.manage_users.pluck(:provider_id)
      provider_ids.map do |id|
        ProviderPermissions.find_or_initialize_by(
          provider_id: id,
          provider_user_id: provider_user.id,
        )
      end
    end

    def save!
      # validate first that the new permissions are all legit
      # nuke all the old permissions and create a fresh set
      possible_permissions.select(&:persisted?).map(&:destroy!)
      @provider_permissions.map(&:save!)
    end

    def provider_permissions=(attributes)
      @provider_permissions = attributes.map do |_id, attrs|
        ProviderPermissions.new(attrs.merge(provider_user_id: provider_user.id))
        # handle assignment of manage_users etc in here too
      end
    end
  end
end
