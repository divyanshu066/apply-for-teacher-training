module ProviderInterface
  class RejectionReasonsForm
    include ActiveModel::Model

    attr_reader :config, :questions

    def initialize
      @config = YAML.load_file(Rails.root.join('config/rejection-reasons.yml')).deep_symbolize_keys
      @questions = @config[:questions].map { |q| Question.new(q) }
    end
  end

  class Question
    attr_reader :label, :type, :answers, :answer_field_type

    def initialize(question_data)
      @label = question_data[:label]
      @type = question_data[:type]
      @answers = question_data[:answers].map { |a| Answer.new(a) }
      @answer_field_type = answers.first.type
    end
  end

  class Answer
    attr_reader :label, :type, :answers

    def initialize(answer_data)
      @label = answer_data[:label]
      @type = answer_data[:type]
      @answers = answer_data.fetch(:answers, []).map { |a| Answer.new(a) }
    end
  end
end
