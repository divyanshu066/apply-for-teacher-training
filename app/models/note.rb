class Note < ApplicationRecord
  belongs_to :application_choice, touch: true
  belongs_to :provider_user

  scope :visible_to, lambda { |provider_user|
    choices_user_can_see = GetApplicationChoicesForProviders.call(
      providers: provider_user.providers,
    )

    where(application_choice_id: choices_user_can_see)
  }
end
