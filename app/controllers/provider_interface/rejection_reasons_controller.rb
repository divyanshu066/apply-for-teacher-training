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
          render inline: "<code>#{params.inspect}</code>"
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
    attr_accessor :explanation
    attr_accessor :answered
    attr_accessor :requires_reasons
    attr_accessor :additional_question

    validates :y_or_n, presence: true
    validate :enough_reasons?, if: -> { y_or_n == 'Y' }
    validate :reasons_all_valid?, if: -> { y_or_n == 'Y' }
    validate :explanation_valid?, if: -> { y_or_n == 'Y' && explanation.present? }

    def initialize(*args)
      super(*args)
      @requires_reasons ||= reasons.count.positive?
    end

    def enough_reasons?
      if requires_reasons && reasons.select(&:selected?).count.zero?
        errors.add(:reasons, 'Please give a reason')
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
    attr_accessor :advice
    attr_writer :textareas
    validate :textareas_all_valid?, if: -> { value.present? }

    alias_method :id, :label

    def selected?
      value.present?
    end

    def textareas
      @textareas ||= []
    end

    def textareas_all_valid?
      textareas.each_with_index do |t, i|
        next unless t.invalid?

        t.errors.each do |attr, message|
          errors.add("textareas[#{i}].#{attr}", message)
        end
      end
    end

    def textareas_attributes=(attributes)
      @textareas ||= []
      attributes.each do |_id, r|
        @textareas.push(RejectionReasonTextarea.new(r))
      end
    end
  end

  class RejectionReasonTextarea
    include ActiveModel::Model

    attr_accessor :label
    attr_accessor :value

    validates :value, presence: true
  end

  class RejectionReasonsForm
    include ActiveModel::Model

    QUESTIONS = [
      RejectionReasonQuestion.new(
        label: :candidate_behaviour,
        reasons: [
          RejectionReasonReason.new(label: :no_reply_to_interview, textareas: [
            RejectionReasonTextarea.new(label: :no_reply_explanation)
          ]),
          RejectionReasonReason.new(label: :no_attendance_at_interview, textareas: [
            RejectionReasonTextarea.new(label: :no_attendance_explanation)
          ]),
          RejectionReasonReason.new(label: :other, textareas: [
            RejectionReasonTextarea.new(label: :other_details),
            RejectionReasonTextarea.new(label: :other_advice),
          ]),
        ],
        explanation: RejectionReasonTextarea.new(label: :explain_candidate_behavior),
      ),
      RejectionReasonQuestion.new(
        label: :quality_of_application,
        reasons: [
          RejectionReasonReason.new(label: :personal_statement),
          RejectionReasonReason.new(label: :subject_knowledge),
        ],
      ),
    ]

    attr_writer :questions
    validate :questions_all_valid?

    def initialize(*args)
      super(*args)
      assign_answered_questions
    end

    def questions
      @questions || []
    end

    def answered_questions
      @answered_questions || []
    end

    def assign_answered_questions
      @answered_questions, @questions = questions.partition(&:answered)
    end

    def next_step!
      @answered_questions = answered_questions + questions
      @questions = questions_for_current_step
    end

    def questions_for_current_step
      if answered_questions.count == 0
        QUESTIONS.take(1)
      elsif answered_questions.count == 1
        QUESTIONS.drop(1)
      else
        []
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
