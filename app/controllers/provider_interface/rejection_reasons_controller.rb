module ProviderInterface
  class RejectionReasonsController < ProviderInterfaceController
    def new
      @reasons_form = RejectionReasonsForm.new
      @reasons_form.begin!
    end

    def create
      @reasons_form = RejectionReasonsForm.new(form_params)
      if @reasons_form.valid?
        @reasons_form.next_step!
        if @reasons_form.done?
          render inline: "<pre>#{params.inspect}</pre>"
        else
          render :new
        end
      else
        render :new
      end
    end

    def form_params
      params.require('provider_interface_rejection_reasons_form').permit(questions_attributes: {})
    end
  end

  class RejectionReasonQuestion
    include ActiveModel::Model

    attr_accessor :label
    attr_accessor :y_or_n
    attr_accessor :reasons

    validates :y_or_n, presence: true
    validate :enough_reasons?, if: -> { y_or_n == 'Y' }
    validate :reasons_all_valid?, if: -> { y_or_n == 'Y' }

    def enough_reasons?
      if reasons.any? && reasons.select(&:value).count.zero?
        errors.add(:y_or_n, "Please select a reason")
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

  class RejectionReasonsForm
    include ActiveModel::Model

    QUESTIONS = [
      RejectionReasonQuestion.new(
        label: 'QUESTION',
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
        reasons: [
          RejectionReasonReason.new(label: 'Reason1'),
          RejectionReasonReason.new(label: 'Reason2'),
        ],
      ),
    ]

    attr_writer :questions
    validate :questions_all_valid?

    def questions
      @questions || []
    end

    def answered_questions
      @answered_questions || []
    end

    def next_step!
      @answered_questions = answered_questions + questions
      if @answered_questions.count == 0
        @questions = QUESTIONS.take(2)
      elsif @answered_questions.count == 2 # or whatever
        @questions = QUESTIONS.drop(2)
      else # no further questions
        @questions.clear
      end
    end

    alias_method :begin!, :next_step!

    def done?
      @answered_questions.any? && @questions.empty?
    end

    def questions_all_valid?
      questions.each_with_index do |q, i|
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
end
