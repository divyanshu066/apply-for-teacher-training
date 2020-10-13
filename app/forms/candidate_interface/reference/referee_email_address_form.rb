module CandidateInterface
  class Reference::RefereeEmailAddressForm
    include ActiveModel::Model

    attr_accessor :email_address, :reference_id

    validates :email_address, presence: true,
                              email_address: true,
                              length: { maximum: 100 }

    validates :reference_id, presence: true

    validate :email_address_unique?

    def self.build_from_reference(reference)
      new(
        email_address: reference.email_address&.downcase,
        reference_id: reference.id,
      )
    end

    def save(reference)
      return false unless valid?

      reference.update!(email_address: email_address)
    end

  private

    def email_address_unique?
      reference = ApplicationReference.find(reference_id)
      current_email_addresses = (reference.application_form.application_references.map(&:email_address) - [reference.email_address]).compact
      return true if current_email_addresses.blank? || email_address.blank?

      errors.add(:email_address, :duplicate) if current_email_addresses.map(&:downcase).include?(email_address.downcase)
    end
  end
end
