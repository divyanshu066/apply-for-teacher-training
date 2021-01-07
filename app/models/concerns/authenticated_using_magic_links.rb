module AuthenticatedUsingMagicLinks
  extend ActiveSupport::Concern

  included do
    has_many :authentication_tokens, as: :user, dependent: :destroy
  end

  def create_magic_link_token!
    magic_link_token = MagicLinkToken.new
    authentication_tokens.create!(hashed_token: magic_link_token.encrypted)
    magic_link_token.raw
  end
end