module CandidateInterface
  class GcseQualificationReviewComponent < ViewComponent::Base
    def initialize(application_form:, application_qualification:, subject:, editable: true, heading_level: 2, missing_error: false, submit_application_attempt: false)
      @application_form = application_form
      @application_qualification = application_qualification
      @subject = subject
      @editable = editable
      @heading_level = heading_level
      @missing_error = missing_error
      @submit_application_attempt = submit_application_attempt
    end

    def gcse_qualification_rows
      if application_qualification.missing_qualification?
        [missing_qualification_row]
      else
        [
          qualification_row,
          award_year_row,
          grade_row,
        ]
      end
    end

    def show_missing_banner?
      gcse_completed = "#{@subject}_gcse_completed"
      if @submit_application_attempt && FeatureFlag.active?('mark_every_section_complete')
        !@application_form.send(gcse_completed) && @editable
      else
        @editable && !@application_qualification
      end
    end

  private

    attr_reader :application_qualification, :subject

    def qualification_row
      {
        key: t('application_form.degree.qualification.label'),
        value: gcse_qualification_types[application_qualification.qualification_type.to_sym.downcase],
        action: "qualification for #{gcse_qualification_types[application_qualification.qualification_type.to_sym]}, #{subject}",
        change_path: candidate_interface_gcse_details_edit_type_path(subject: subject),
      }
    end

    def award_year_row
      {
        key: 'Year awarded',
        value: application_qualification.award_year || t('gcse_summary.not_specified'),
        action: "year awarded for #{gcse_qualification_types[application_qualification.qualification_type.to_sym]}, #{subject}",
        change_path: candidate_interface_gcse_details_edit_year_path(subject: subject),
      }
    end

    def grade_row
      {
        key: 'Grade',
        value: application_qualification.grade ? application_qualification.grade.upcase : t('gcse_summary.not_specified'),
        action: "grade for #{gcse_qualification_types[application_qualification.qualification_type.to_sym]}, #{subject}",
        change_path: candidate_interface_gcse_details_edit_grade_path(subject: subject),
      }
    end

    def missing_qualification_row
      {
        key: 'How I expect to gain this qualification',
        value: application_qualification.missing_explanation.presence || t('gcse_summary.not_specified'),
        action: 'how do you expect to gain this qualification',
        change_path: candidate_interface_gcse_details_edit_type_path(subject: subject),
      }
    end

    def gcse_qualification_types
      t('application_form.gcse.qualification_types').merge(
        other_uk: application_qualification.other_uk_qualification_type,
      )
    end
  end
end
