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
    attr_accessor :answered
    attr_accessor :additional_question

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
    attr_accessor :advice
    attr_accessor :textarea
    validates :explanation, presence: true, if: -> { reason_with_textarea_selected? }

    alias_method :id, :label

    private

    def reason_with_textarea_selected?
      value.present? && textarea.present?
    end
  end

  class RejectionReasonsForm
    include ActiveModel::Model

    QUESTIONS = [
      [
        RejectionReasonQuestion.new(
          label: 'Was it related to candidate behaviour?',
          additional_question: 'What did the candidate do?',
          reasons: [
            RejectionReasonReason.new(label: 'Didn’t reply to our interview offer'),
            RejectionReasonReason.new(label: 'Didn’t attend interview'),
            RejectionReasonReason.new(label: 'Other', textareas: %i[explanation advice]),
          ],
        ),
        RejectionReasonQuestion.new(
          label: 'Was it related to the quality of their application?',
          additional_question: 'Which parts of the application needed improvement?',
          reasons: [
            RejectionReasonReason.new(label: 'Personal statement'),
            RejectionReasonReason.new(label: 'Subject knowledge'),
            RejectionReasonReason.new(label: 'Other', textareas: [:advice]),
          ],
        ),
        RejectionReasonQuestion.new(
          label: 'Was it related to qualifications?',
          additional_question: 'Which qualifications?',
          reasons: [
            RejectionReasonReason.new(label: 'No Maths GCSE grade 4 (C) or above, or valid equivalent'),
            RejectionReasonReason.new(label: 'Other', textareas: [:explanation]),
          ],
        ),
      ],
      [
        RejectionReasonQuestion.new(
          label: 'Why are you rejecting this application?',
          reasons: [
            RejectionReasonReason.new(textarea: [:explanation]),
          ],
        ),
        RejectionReasonQuestion.new(
          label: 'Is there any other advice or feedback you’d like to give?',
          reasons: [
            RejectionReasonReason.new(label: 'Please give details', textareas: [:explanation]),
          ],
        ),

      ],
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
        QUESTIONS.first
      elsif answered_questions.map(&:y_or_n).flatten.last(2).include?('N')
        QUESTIONS.last
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
