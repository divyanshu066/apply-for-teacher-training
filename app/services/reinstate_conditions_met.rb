class ReinstateConditionsMet
  include ActiveModel::Validations

  attr_reader :application_choice, :course_option

  validates :course_option, presence: true
  validate :validate_course_option_is_open_on_apply
  validate :validate_course_option_belongs_to_current_cycle

  def initialize(actor:, application_choice:, course_option:)
    @auth = ProviderAuthorisation.new(actor: actor)
    @application_choice = application_choice
    @course_option = course_option
  end

  def save
    @auth.assert_can_make_decisions!(application_choice: application_choice, course_option_id: @course_option.id)

    if valid?
      attrs = { offered_course_option_id: @course_option.id }
      attrs[:recruited_at] = Time.zone.now unless application_choice.status_before_deferral == 'recruited' # conditions are 'still met'

      ActiveRecord::Base.transaction do
        ApplicationStateChange.new(application_choice).reinstate_conditions_met!
        application_choice.update(attrs)
        StateChangeNotifier.call(:reinstate_offer_conditions_met, application_choice: application_choice)
      end
    end
  rescue Workflow::NoTransitionAllowed
    errors.add(
      :base,
      I18n.t('activerecord.errors.models.application_choice.attributes.status.invalid_transition'),
    )
    false
  end

  def validate_course_option_is_open_on_apply
    if course_option.present? && !course_option.course.open_on_apply
      errors.add(:course_option, :not_open_on_apply)
    end
  end

  def validate_course_option_belongs_to_current_cycle
    if course_option.present? && course_option.course.recruitment_cycle_year != RecruitmentCycle.current_year
      errors.add(:course_option, :not_in_current_cycle)
    end
  end
end
