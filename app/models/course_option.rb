class CourseOption < ApplicationRecord
  belongs_to :course
  belongs_to :site
  has_many :application_choices

  audited associated_with: :provider
  delegate :provider, to: :course

  validates :vacancy_status, presence: true
  validate :validate_providers

  scope :selectable, -> { where(site_still_valid: true) }
  scope :available, lambda {
    selectable.joins(:course).where(vacancy_status: 'vacancies').or(
      selectable.joins(:course).where(courses: { force_open: true })
    )
  }

  enum study_mode: {
    full_time: 'full_time',
    part_time: 'part_time',
  }

  enum vacancy_status: {
    vacancies: 'vacancies',
    no_vacancies: 'no_vacancies',
  }

  def no_vacancies?
    !course.force_open && vacancy_status == 'no_vacancies'
  end

  def validate_providers
    return unless site.present? && course.present?

    return if site.provider == course.provider

    errors.add(:site, 'must have the same Provider as the course')
  end

  def course_not_available?
    !course.exposed_in_find?
  end

  def course_closed_on_apply?
    !course.open_on_apply?
  end

  delegate :full?, to: :course, prefix: true

  def course_withdrawn?
    course.withdrawn
  end

  def alternative_study_mode
    (course.available_study_modes_from_options - [study_mode]).first
  end

  def get_alternative_study_mode
    CourseOption.find_by(site: site, course: course, study_mode: alternative_study_mode)
  end
end
