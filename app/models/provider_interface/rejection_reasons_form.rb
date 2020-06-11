module ProviderInterface
  class RejectionReasonsForm
    include ActiveModel::Model

    attr_reader :config, :questions

    def initialize
      @config = YAML.load_file(Rails.root.join('config/rejection-reasons.yml')).deep_symbolize_keys
      @questions = @config[:questions].map { |q| Question.new(q) }
    end

    def populate_answers(params)
      # Do something with params to populate the 'value' attributes on answers.
    end
  end

  class Question
    attr_reader :label, :type, :answers, :answer_field_type

    def initialize(question_data)
      @label = question_data[:label]
      @type = question_data[:type]
      @answers = question_data[:answers].map { |a| Answer.new(a, self) }
      @answer_field_type = answers.first.type
    end

    def valid?
      answers.map(&:valid?).include?(true)
    end
  end

  class Answer
    attr_reader :id, :field_name, :label, :type, :answers
    attr_accessor :value

    def initialize(answer_data, parent)
      @label = answer_data[:label]
      @type = answer_data[:type]
      @answers = answer_data.fetch(:answers, []).map { |a| Answer.new(a, self) }
      @id = parent.label.parameterize.concat('-', label.parameterize)
      @field_name = parent.label.parameterize.gsub('-', '_')
    end

    def valid?
      return answers.map(&:valid?).include(true) if answers.any?

      value.present?
    end
  end
end
