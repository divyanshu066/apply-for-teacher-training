module SupportInterface
  class OfferConditionsExport
    def offers
      relevant_choices.flat_map do |choice|
        {
          support_reference: choice.application_form.support_reference,
          phase: choice.application_form.phase,
          recruitment_cycle: choice.recruitment_cycle,
          qualification_type: qualification_type(choice.application_form),
          qualification_subject: qualification_subject(choice.application_form),
          qualification_grade: qualification_grade(choice.application_form),
          start_year: start_year(choice.application_form),
          award_year: award_year(choice.application_form),
          provider_code: choice.provider.code,
          provider_name: choice.provider.name,
          course_code: choice.course.code,
          course_name: choice.course.name,
          course_location: choice.site.name,
          course_study_mode: choice.course_option.study_mode,
          offered_provider_name: choice.offered_option.provider.name,
          offered_provider_code: choice.offered_option.provider.code,
          offered_course_code: choice.offered_course.code,
          offered_course_name: choice.offered_course.name,
          offered_course_location: choice.offered_site.name,
          offered_course_study_mode: choice.offered_option.study_mode,
          offer_changed: choice.offered_option != choice.course_option,
          offer_made_at: choice.offered_at.to_s(:govuk_date),
          application_status: choice.status,
          conditions: conditions(choice),
        }
      end
    end

    alias_method :data_for_export, :offers

  private

    def qualification_type(form)
      qualifications(form).map(&:level).join(',')
    end

    def qualification_subject(form)
      qualifications(form).map(&:subject).join(',')
    end

    def qualification_grade(form)
      qualifications(form).map(&:grade).join(',')
    end

    def start_year(form)
      qualifications(form).map(&:start_year).join(',')
    end

    def award_year(form)
      qualifications(form).map(&:award_year).join(',')
    end

    def qualifications(form)
      form.application_qualifications.order(:created_at)
    end

    def conditions(choice)
      choice.offer['conditions'].join(',')
    end

    def relevant_choices
      ApplicationChoice
        .where('offer IS NOT NULL')
        .order('offered_at asc')
    end
  end
end
