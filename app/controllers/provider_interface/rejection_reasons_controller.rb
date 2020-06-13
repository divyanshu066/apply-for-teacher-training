module ProviderInterface
  class RejectionReasonsController < ProviderInterfaceController
    def new
      @reasons_form = form
      @reasons_form.assign_attributes(current_step: 1)
    end

    def form
      RejectionReasonsForm.new(
        questions: [
          RejectionReasonQuestion.new(
            label: 'QUESTION',
            type: :question_with_multiple_reasons,
            reasons: [
              RejectionReasonReason.new(label: 'Reason1'),
              RejectionReasonReason.new(label: 'Reason2'),
            ],
          ),
          RejectionReasonQuestion.new(
            label: 'QUESTION2',
            reasons: [
              RejectionReasonReason.new(label: 'Reason1'),
              RejectionReasonReason.new(label: 'Reason2'),
            ],
          ),
          RejectionReasonQuestion.new(
            label: 'QUESTION3',
            type: :yes_or_no_question,
          ),
        ],
      )
    end

    def create
      @reasons_form = RejectionReasonsForm.new(form_params)
      if !@reasons_form.valid?
        render :new
      elsif @reasons_form.next_step?
        @reasons_form.next_step!
        render :new
      else
        raise
        render inline: "<pre>#{params.inspect}</pre>"
      end
    end

    def form_params
      params.require('provider_interface_rejection_reasons_form').permit(:current_step, questions_attributes: {})
    end
  end

  class RejectionReasonsForm
    include ActiveModel::Model

    STEPS = {
      1 => %w[
        QUESTION QUESTION2
      ],
      2 => %w[
        QUESTION3
      ],
    }.freeze

    attr_accessor :questions
    attr_writer :current_step

    def current_step
      @current_step.to_i
    end

    validate :questions_all_valid?

    def questions_for_previous_steps
      (current_step - 1).downto(1).reduce([]) do |qs, step|
        qs + questions_for_step(step)
      end
    end

    def questions_for_future_steps
      (current_step + 1).upto(STEPS.keys.max).reduce([]) do |qs, step|
        qs + questions_for_step(step)
      end
    end

    def questions_for_current_step
      questions_for_step(current_step)
    end

    def questions_for_step(step)
      questions.select { |q| STEPS[step].include?(q.label) }
    end

    def next_step?
      current_step == 1
    end

    def next_step!
      @current_step = 2
    end

    def questions_all_valid?
      questions_for_current_step.each_with_index do |q, i|
        next unless q.invalid?

        q.errors.each do |attr, message|
          errors.add("questions[#{i}].#{attr}", message)
        end
      end
    end

    def questions_attributes=(attributes)
      @questions ||= []
      attributes.each do |_id, q|
        @questions.push(RejectionReasonQuestion.new(q))
      end
    end
  end

  class RejectionReasonQuestion
    include ActiveModel::Model

    attr_accessor :label
    attr_accessor :type
    attr_accessor :y_or_n
    attr_accessor :reasons

    validates :y_or_n, presence: true
    validate :enough_reasons?, if: -> { y_or_n == 'Y' }
    validate :reasons_all_valid?, if: -> { y_or_n == 'Y' }

    def enough_reasons?
      if reasons.any? && reasons.select(&:value).count.zero?
        errors.add(:y_or_n, 'Please select a reason')
      end
    end

    def reasons_all_valid?
      reasons.each_with_index do |r, i|
        next unless r.invalid?

        r.errors.each do |attr, message|
          errors.add("reasons[#{i}].#{attr}", message)
        end
      end
    end

    def reasons_attributes=(attributes)
      @reasons ||= []
      attributes.each do |_id, r|
        @reasons.push(RejectionReasonReason.new(r))
      end
    end

    alias_method :id, :label
  end

  class RejectionReasonReason
    include ActiveModel::Model

    attr_accessor :label
    attr_accessor :value
    attr_accessor :explanation

    validates :explanation, presence: true, if: -> { value.present? }

    alias_method :id, :label
  end
end
