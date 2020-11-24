module TeacherTrainingAPI
  class Course < TeacherTrainingAPI::Resource
    belongs_to :recruitment_cycle, through: :provider, param: :year
    belongs_to :provider, param: :provider_code

    def self.fetch(recruitment_cycle_year: RecruitmentCycle.current_year, provider_code:, course_code:)
      where(year: recruitment_cycle_year)
        .where(provider_code: provider_code)
        .find(course_code)
        .first
    rescue JsonApiClient::Errors::NotFound
      nil
    rescue JsonApiClient::Errors::ServerError, JsonApiClient::Errors::ConnectionError => e
      Raven.capture_exception(e)
      nil
    end
  end
end
