module FindSync
  class SyncCoursesFromFind
    attr_reader :provider

    include Sidekiq::Worker
    sidekiq_options retry: 3, queue: :low_priority

    def perform(provider_id, provider_recruitment_cycle_year)
      @provider = Provider.find(provider_id)
      @provider_recruitment_cycle_year = provider_recruitment_cycle_year

      find_provider.courses.each do |find_course|
        teacher_training_api_course = TeacherTrainingAPI::Course.fetch(
          recruitment_cycle_year: provider_recruitment_cycle_year,
          provider_code: @provider.code,
          course_code: find_course.course_code,
        )
        create_or_update_course(find_course, teacher_training_api_course)
      end
    rescue JsonApiClient::Errors::ApiError
      raise FindSync::SyncError
    end

  private

    def find_provider
      # https://api2.publish-teacher-training-courses.service.gov.uk/api/v3/recruitment_cycles/2020/providers/1N1/?include=sites,courses.sites
      @find_provider ||= begin
        FindAPI::Provider
          .recruitment_cycle(@provider_recruitment_cycle_year)
          .includes(:sites, courses: [:sites, :subjects, site_statuses: [:site]])
          .find(provider.code)
          .first
      end
    end

    def create_or_update_course(find_course, teacher_training_api_course)
      course = provider.courses.find_or_create_by(
        code: find_course.course_code,
        recruitment_cycle_year: find_course.recruitment_cycle_year,
      ) do |new_course|
        new_course.open_on_apply = if new_course.in_previous_cycle&.open_on_apply
                                     true
                                   else
                                     false
                                   end
      end

      assign_course_attributes_from_find(course, find_course)
      assign_course_attributes_from_teacher_training_api(course, teacher_training_api_course)

      add_accredited_provider(course, find_course[:accrediting_provider])

      course.save!

      add_provider_relationships(course)

      site_statuses = find_course.site_statuses
      find_course.sites.each do |find_site|
        site = provider.sites.find_or_create_by(code: find_site.code)

        site.name = find_site.location_name
        site.address_line1 = find_site.address1&.strip
        site.address_line2 = find_site.address2&.strip
        site.address_line3 = find_site.address3&.strip
        site.address_line4 = find_site.address4&.strip
        site.postcode = find_site.postcode&.strip
        site.save!

        find_site_status = site_statuses.find { |ss| ss.site.id == find_site.id }

        study_modes = FindSync::CourseStudyModes.new(course).derive

        study_modes.each do |mode|
          course_option = CourseOption.find_or_initialize_by(
            site: site,
            course_id: course.id,
            study_mode: mode,
          )

          vacancy_status = FindSync::CourseVacancyStatus.new(
            find_site_status.vac_status,
            course_option.study_mode,
          ).derive

          course_option.update!(vacancy_status: vacancy_status)
        end
      end

      handle_course_options_with_invalid_sites(course, find_course)
    end

    def assign_course_attributes_from_find(course, find_course)
      course.name = find_course.name
      course.level = find_course.level
      course.study_mode = find_course.study_mode
      course.description = find_course.description
      course.start_date = find_course.start_date
      course.course_length = find_course.course_length
      course.recruitment_cycle_year = find_course.recruitment_cycle_year
      course.exposed_in_find = find_course.findable?
      course.subject_codes = find_course.subject_codes
      course.funding_type = find_course.funding_type
      course.age_range = find_course.age_range_in_years&.humanize
      course.withdrawn = find_course.content_status == 'withdrawn'
    end

    def assign_course_attributes_from_teacher_training_api(course, teacher_training_api_course)
      course.program_type = teacher_training_api_course.program_type
      course.qualifications = teacher_training_api_course.qualifications
    end

    def add_accredited_provider(course, find_accredited_provider)
      if find_accredited_provider.present? && course.provider.code != find_accredited_provider[:provider_code]
        accredited_provider = Provider.find_or_initialize_by(code: find_accredited_provider[:provider_code])
        accredited_provider.name = find_accredited_provider[:provider_name]
        accredited_provider.save!

        course.accredited_provider = accredited_provider
      else
        course.accredited_provider = nil
      end
    end

    def add_provider_relationships(course)
      return if course.accredited_provider.blank?
      return if course.accredited_provider == course.provider

      ProviderRelationshipPermissions.find_or_create_by!(
        training_provider: provider,
        ratifying_provider: course.accredited_provider,
      )
    end

    def handle_course_options_with_invalid_sites(course, find_course)
      course_options = course.course_options.joins(:site)
      canonical_site_codes = find_course.sites.map(&:code)
      invalid_course_options = course_options.where.not(sites: { code: canonical_site_codes })
      return if invalid_course_options.blank?

      chosen_course_option_ids = ApplicationChoice
        .where(course_option: invalid_course_options)
        .or(ApplicationChoice.where(offered_course_option: invalid_course_options))
        .pluck(:course_option_id, :offered_course_option_id).flatten.uniq

      not_part_of_an_application = invalid_course_options.where.not(id: chosen_course_option_ids)
      not_part_of_an_application.delete_all
      part_of_an_application = invalid_course_options.where(id: chosen_course_option_ids)

      return if part_of_an_application.size.zero?

      part_of_an_application.each do |course_option|
        next if course_option.site_still_valid == false

        course_option.update!(site_still_valid: false)
      end
    end
  end
end
