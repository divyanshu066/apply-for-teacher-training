class DegreeQualificationCardsComponent < ViewComponent::Base
  attr_reader :degrees, :application_choice_state

  def initialize(degrees, application_choice_state: nil)
    @degrees = degrees
    @application_choice_state = application_choice_state
  end

  def section_title
    'Degree'.pluralize(degrees.count)
  end

  def degree_type_and_subject(degree)
    "#{degree_type_with_honours(degree)} #{degree.subject}"
  end

  def formatted_grade(degree)
    if degree.predicted_grade?
      "Predicted: #{degree.grade}"
    else
      degree.grade
    end
  end

  def show_institution?
    # Always show the institution if the component has not been made aware of
    # any application choice state
    return true if application_choice_state.nil?

    application_choice_state.to_sym.in? ApplicationStateChange::ACCEPTED_STATES
  end

  def formatted_institution(degree)
    degree.international? ? institution_and_country(degree) : institution(degree)
  end

  def naric_statement(degree)
    if degree.naric_reference.present? && degree.comparable_uk_degree.present?
      degree_name = I18n.t("application_form.degree.comparable_uk_degree.values.#{degree.comparable_uk_degree}")
      "NARIC statement #{degree.naric_reference} says this is comparable to a #{degree_name}"
    end
  end

private

  def degree_type_with_honours(degree)
    if degree.grade&.include? 'honours'
      "#{abbreviate_degree(degree.qualification_type)} (Hons)"
    else
      abbreviate_degree(degree.qualification_type)
    end
  end

  def abbreviate_degree(name)
    Hesa::DegreeType.find_by_name(name)&.abbreviation || name
  end

  def institution_and_country(degree)
    "#{institution(degree)}, #{COUNTRIES[degree.institution_country]}"
  end

  def institution(degree)
    degree.institution_name
  end
end