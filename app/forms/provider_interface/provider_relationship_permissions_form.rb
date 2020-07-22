module ProviderInterface
  class ProviderRelationshipPermissionsForm
    include ActiveModel::Model

    attr_accessor :permissions

    delegate :errors, to: :permissions

    def assign_permissions_attributes(attrs)
      @permissions.assign_attributes(permissions_attributes(attrs))
    end

    def update!(attrs)
      permissions_attrs = permissions_attributes(attrs)

      @permissions.assign_attributes(permissions_attrs)

      if @permissions.valid?
        @permissions.update!(permissions_attrs)
      end
    end

  private

    def permissions_attributes(attrs)
      merged_attrs = attrs.values.reduce({}, :merge).symbolize_keys

      {}.tap do |hash|
        ProviderRelationshipPermissions.permissions_fields.each do |f|
          hash[f] = merged_attrs.fetch(f, false)
        end
      end
    end
  end
end
