class ProviderRelationshipPermissions < ApplicationRecord
  belongs_to :ratifying_provider, class_name: 'Provider'
  belongs_to :training_provider, class_name: 'Provider'

  PERMISSIONS = %i[make_decisions view_safeguarding_information].freeze

  validate :at_least_one_active_permission_in_pair, if: -> { setup_at.present? }

  def self.permissions_fields
    @permissions_fields ||= [].tap do |ary|
      PERMISSIONS.each do |permission_name|
        ary << :"ratifying_provider_can_#{permission_name}"
        ary << :"training_provider_can_#{permission_name}"
      end
    end
  end

  def training_provider_can_view_applications_only?
    PERMISSIONS.map { |permission| send("training_provider_can_#{permission}") }.all?(false)
  end

  def ratifying_provider_can_view_applications_only?
    PERMISSIONS.map { |permission| send("ratifying_provider_can_#{permission}") }.all?(false)
  end

private

  def at_least_one_active_permission_in_pair
    PERMISSIONS.each do |permission|
      if !send("training_provider_can_#{permission}") && !send("ratifying_provider_can_#{permission}")
        errors.add(permission, "At least one organisation must have permission to #{permission.to_s.humanize.downcase}")
      end
    end
  end
end
