class ProviderRelationshipPermissions < ApplicationRecord
  belongs_to :ratifying_provider, class_name: 'Provider'
  belongs_to :training_provider, class_name: 'Provider'

  PERMISSIONS = %i[make_decisions view_safeguarding_information].freeze

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
end
