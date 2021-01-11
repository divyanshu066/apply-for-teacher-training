module ProviderInterface
  class NewInterviewForm
    include ActiveModel::Model
    attr_accessor :application_choice, :subject, :message, :provider_user

    validates :application_choice, :provider_user, presence: true
    validates :subject, length: { maximum: 40 }, presence: true
    validates :message, length: { maximum: 500 }, presence: true

    def save
      if valid?
        Note.new(
          application_choice: application_choice,
          provider_user: provider_user,
          subject: subject,
          message: message,
        ).save
      end
    end
  end
end
