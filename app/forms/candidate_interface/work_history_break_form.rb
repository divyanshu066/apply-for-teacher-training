module CandidateInterface
  class WorkHistoryBreakForm
    include ActiveModel::Model
    include DateValidationHelper

    attr_accessor :start_date_day, :start_date_month, :start_date_year,
                  :end_date_day, :end_date_month, :end_date_year, :reason

    validates :start_date, date: { future: true, month_and_year: true }
    validates :end_date, date: { future: true, month_and_year: true, presence: true }
    validate :start_date_before_end_date, unless: ->(c) { %i[start_date end_date].any? { |d| c.errors.keys.include?(d) } }

    validates :reason, presence: true, word_count: { maximum: 400 }

    def self.build_from_break(work_history_break)
      new(
        start_date_day: work_history_break.start_date.day,
        start_date_month: work_history_break.start_date.month,
        start_date_year: work_history_break.start_date.year,
        end_date_day: work_history_break.end_date.day,
        end_date_month: work_history_break.end_date.month,
        end_date_year: work_history_break.end_date.year,
        reason: work_history_break.reason,
      )
    end

    def save(application_form)
      return false unless valid?

      application_form.application_work_history_breaks.create!(
        start_date: start_date, end_date: end_date, reason: reason,
      )
    end

    def update(work_break)
      return false unless valid?

      work_break.update!(
        start_date: start_date, end_date: end_date, reason: reason,
      )
    end

    def start_date
      valid_or_invalid_date(start_date_year, start_date_month)
    end

    def end_date
      valid_or_invalid_date(end_date_year, end_date_month)
    end
  end
end
