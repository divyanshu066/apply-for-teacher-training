module SupportInterface
  class Task < ApplicationRecord
    belongs_to :support_user
  end
end
