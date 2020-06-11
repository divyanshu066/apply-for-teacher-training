module ProviderInterface
  class RejectionReasonsForm
    include ActiveModel::Model

    attr_reader :config, :questions

    def initialize
      @config = YAML.load_file(Rails.root.join('config/rejection-reasons.yml')).deep_symbolize_keys
      @questions = @config[:questions].map { |q| Question.new(q) }
    end

    def populate_answers(questions, params)
      questions.each do |question|
        params[question.name].each do |answer_value|
          if answer_value.is_a?(Hash)
            answer = find_answer_by_matching_questions(question, answer_value)
            populate_answers(answer.questions, answer_value)
          else
            answer = find_answer_to_question(question, answer_value)
            answer.value = answer_value
          end
        end
      end
    end

  private

    def find_answer_by_matching_questions(question, answer_hash)
      question.answers.find { |a| a.questions.map(&:name) == answer_hash.keys }
    end

    def find_answer_to_question(question, label)
      return question.answers.first if question.answer_field_type == 'textarea'

      question.answers.find { |a| a.label == label }
    end
  end

  class Question
    attr_reader :label, :type, :answers, :answer_field_type, :parent

    def initialize(question_data, parent = nil)
      @label = question_data[:label]
      @type = question_data[:type]
      @parent = parent
      @answers = question_data[:answers].map { |a| Answer.new(a, self) }
      @answer_field_type = answers.first.type
    end

    def id
      return label.parameterize unless parent

      parent.label.parameterize.concat('-', label.parameterize)
    end

    def name
      label.parameterize.gsub('-', '_')
    end

    def field_name
      return "rejection_reasons_form[#{name}][]" unless parent

      "#{parent.field_name}[#{name}][]"
    end

    def valid?
      answers.map(&:valid?).include?(true)
    end
  end

  class Answer
    include ActiveModel::Model

    attr_reader :id, :label, :type, :questions, :parent
    attr_accessor :value

    validates :value, presence: true

    delegate :field_name, to: :parent

    def initialize(answer_data, parent)
      @parent = parent
      @label = answer_data[:label]
      @type = answer_data[:type]
      @id = parent.label.parameterize.concat('-', label.parameterize)
      @questions = answer_data.fetch(:questions, []).map { |q| Question.new(q, self) }
    end

    def valid?
      return questions.map(&:valid?).include?(true) if questions.any?

      super
    end
  end
end
