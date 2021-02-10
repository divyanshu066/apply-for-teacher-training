class GetApplicationChoicesForProviders
  DEFAULT_INCLUDES = [
    :accredited_provider,
    :offered_course_option,
    :provider,
    :site,
    application_form: %i[candidate application_references application_work_experiences application_volunteering_experiences application_qualifications],
    course: %i[provider accredited_provider],
    course_option: [{ course: %i[provider] }, :site],
  ].freeze

  DEFAULT_RECRUITMENT_CYCLE_YEAR = RecruitmentCycle.years_visible_to_providers

  def self.call(providers:, vendor_api: false, includes: DEFAULT_INCLUDES, recruitment_cycle_year: DEFAULT_RECRUITMENT_CYCLE_YEAR)
    providers = Array.wrap(providers).select(&:present?)

    raise MissingProvider if providers.none?

    statuses = vendor_api ? ApplicationStateChange.states_visible_to_provider_without_deferred :
                            ApplicationStateChange.states_visible_to_provider

    provider_courses = Course.where(provider: providers)
                             .or(Course.where(accredited_provider: providers))
                             .where(recruitment_cycle_year: recruitment_cycle_year)

    applications = ApplicationChoice.joins(:course).merge(provider_courses)
                                    .left_joins(:offered_course).merge(provider_courses)
                                    .where(status: statuses)

    applications.includes(*includes)
  end
end
