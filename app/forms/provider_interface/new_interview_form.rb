module ProviderInterface
  class NewInterviewForm
    include ActiveModel::Model

    attr_accessor :day, :month, :year, :time

    validate :date_is_valid
    validate :time_is_valid
    validate :date_and_time_in_future, if: -> form { form.date_is_valid && form.time_is_valid }

    def date_and_time
      Date.new()
    end

    def date_is_valid
      date_args = [year, month, day].map(&:to_i)
      binding.pry
      errors[:date] << 'Enter a date' unless Date.valid_date?(*date_args)
    end

    def time_is_valid
      # TODO: Validation to check this is valid!
      errors[:date] << 'Enter a time' unless time.blank?
    end

    def date_and_time_in_future
      errors[:time] << 'Enter a date and time in the future' if date_and_time < Time.zone.now
    end
  end
end
