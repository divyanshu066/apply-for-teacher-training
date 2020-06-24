class Course < ApplicationRecord
  belongs_to :provider
  has_many :course_options
  has_many :application_choices, through: :course_options
  belongs_to :accredited_provider, class_name: 'Provider', optional: true

  audited associated_with: :provider

  validates :level, presence: true
  validates :code, uniqueness: { scope: %i[recruitment_cycle_year provider_id] }

  scope :open_on_apply, -> { exposed_in_find.where(open_on_apply: true) }
  scope :exposed_in_find, -> { where(exposed_in_find: true) }
  scope :current_cycle, -> { where(recruitment_cycle_year: RecruitmentCycle.current_year) }

  CODE_LENGTH = 4

  # This enum is copied verbatim from Find to maintain consistency
  enum level: {
    primary: 'Primary',
    secondary: 'Secondary',
    further_education: 'Further education',
  }, _suffix: :course

  enum funding_type: {
    fee: 'fee',
    salary: 'salary',
    apprenticeship: 'apprenticeship',
  }

  # also copied from Find
  enum study_mode: {
    full_time: 'F',
    part_time: 'P',
    full_time_or_part_time: 'B',
  }

  # also copied from Find
  enum program_type: {
    higher_education_programme: 'HE',
    school_direct_training_programme: 'SD',
    school_direct_salaried_training_programme: 'SS',
    scitt_programme: 'SC',
    pg_teaching_apprenticeship: 'TA',
  }

  def name_and_description
    "#{name} #{description}"
  end

  def name_and_provider
    "#{name} #{accredited_provider&.name}"
  end

  def name_provider_and_description
    "#{name} #{accredited_provider&.name} #{description}"
  end

  def name_and_code
    "#{name} (#{code})"
  end

  def name_code_and_description
    "#{name} (#{code}) – #{description}"
  end

  def name_code_and_provider
    "#{name} (#{code}) – #{accredited_provider&.name}"
  end

  def name_code_and_age_range
    "#{name} (#{code}) – #{age_range}"
  end

  def name_description_provider_and_age_range
    "#{name} #{description} #{accredited_provider&.name} #{age_range}"
  end

  def provider_and_name_code
    "#{provider.name} - #{name_and_code}"
  end

  def both_study_modes_available?
    study_mode == 'full_time_or_part_time'
  end

  def supports_study_mode?(mode)
    both_study_modes_available? || study_mode == mode
  end

  def available_study_modes_from_options
    course_options.pluck(:study_mode).uniq
  end

  def full?
    course_options.all?(&:no_vacancies?)
  end

  def find_url
    "https://www.find-postgraduate-teacher-training.service.gov.uk/course/#{provider.code}/#{code}"
  end

  def in_previous_cycle
    Course.find_by(recruitment_cycle_year: recruitment_cycle_year - 1, provider_id: provider_id, code: code)
  end

  def application_forms
    ApplicationForm
      .includes(:candidate, :application_choices)
      .joins(application_choices: :course_option)
      .where(application_choices: { course_options: { course: self } })
      .distinct
  end
end
