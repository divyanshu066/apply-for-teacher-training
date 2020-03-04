require 'csv'

module ProviderInterface
  class ApplicationChoicesCsvPresenter
    attr_reader :application_choices

    def initialize(application_choices)
      @application_choices = application_choices
    end

    def self.filename
      "applications-#{Time.current.to_s(:number)}.csv"
    end

    def present
      CSV.generate(headers: true) do |csv|
        csv << %w[Reference Name Course Status Updated]
        application_choices.each { |choice| csv << csv_row(choice) }
      end
    end

  private

    def csv_row(choice)
      ApplicationChoiceCsvPresenter.new(choice).present
    end
  end

  class ApplicationChoiceCsvPresenter
    attr_reader :application_choice

    delegate :application_form, to: :application_choice
    delegate :first_name, :last_name, :support_reference, to: :application_form

    def initialize(application_choice)
      @application_choice = application_choice
    end

    def present
      [support_reference, full_name, course_name_and_code, status, updated_at]
    end

  private

    def full_name
      "#{first_name} #{last_name}"
    end

    def course_name_and_code
      application_choice.course.name_and_code
    end

    def status
      application_choice.status.humanize
    end

    def updated_at
      application_choice.updated_at.to_s(:iso8601)
    end
  end
end
