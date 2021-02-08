module SupportInterface
  class ReasonsForRejectionSearchResultsComponent < ViewComponent::Base
    include ViewHelper

    def initialize(search_attribute:, search_value:, application_choices:)
      @search_attribute = search_attribute
      @search_value = search_value
      @application_choices = application_choices
    end

    def summary_list_rows_for(application_choice)
      application_choice.structured_rejection_reasons.map { |reason, value|
        next unless top_level_reason?(reason, value)

        {
          key: reason_text_for(reason),
          value: reason_detail_text_for(application_choice, reason),
        }
      }.compact
    end

    def search_title_text
      if @search_value == 'Yes'
        i18n_key = SupportInterface::SubReasonsForRejectionTableComponent::TOP_LEVEL_REASONS_TO_I18N_KEYS[@search_attribute].to_s
        t("reasons_for_rejection.#{i18n_key}.title")
      else
        top_level_reason = ReasonsForRejectionCountQuery::SUBREASONS_TO_TOP_LEVEL_REASONS[@search_attribute.to_sym]
        i18n_key = SupportInterface::SubReasonsForRejectionTableComponent::TOP_LEVEL_REASONS_TO_I18N_KEYS[top_level_reason].to_s
        [
          t("reasons_for_rejection.#{i18n_key}.title"),
          t("reasons_for_rejection.#{i18n_key}.#{@search_value}"),
        ].join(' - ')
      end
    end

    def reason_detail_text_for(application_choice, top_level_reason)
      sub_reason = sub_reason_for(top_level_reason)
      if sub_reason.present?
        values_as_list(
          application_choice.structured_rejection_reasons[sub_reason]
            &.map { |value| sub_reason_detail_text(application_choice, top_level_reason, sub_reason, value) },
        )
      else
        detail_reason_for(application_choice, top_level_reason)
      end
    end

    def sub_reason_detail_text(application_choice, top_level_reason, sub_reason, value)
      i18n_key = SupportInterface::SubReasonsForRejectionTableComponent::TOP_LEVEL_REASONS_TO_I18N_KEYS[top_level_reason].to_s
      text = mark_search_term(
        I18n.t("reasons_for_rejection.#{i18n_key}.#{value}"),
        value.to_s == @search_value.to_s,
      )

      detail_questions = ReasonsForRejection::INITIAL_QUESTIONS.dig(
        top_level_reason.to_sym, sub_reason.to_sym, value.to_sym
      )
      additional_text =
        if detail_questions.is_a?(Array)
          values_as_list(
            detail_questions.map { |detail_question| application_choice.structured_rejection_reasons[detail_question.to_s] }.compact,
          )
        else
          application_choice.structured_rejection_reasons[detail_questions.to_s]
        end

      [text, additional_text].reject(&:blank?).join(' - ').html_safe
    end

    def reason_text_for(top_level_reason)
      i18n_key = SupportInterface::SubReasonsForRejectionTableComponent::TOP_LEVEL_REASONS_TO_I18N_KEYS[top_level_reason].to_s
      mark_search_term(t("reasons_for_rejection.#{i18n_key}.title"), top_level_reason.to_s == @search_attribute.to_s)
    end

    def top_level_reason?(reason, value)
      reason =~ /_y_n$/ && value == 'Yes'
    end

  private

    def values_as_list(values)
      return nil if values.blank?
      return values[0] if values.size == 1

      tag.ul(
        values.map { |value| tag.li(value) }.join.html_safe,
        class: 'govuk-list govuk-list--bullet govuk-!-margin-left-0 govuk-!-margin-right-0',
      ).html_safe
    end

    def mark_search_term(text, mark)
      mark ? "<mark>#{text}</mark>".html_safe : text
    end

    def sub_reason_for(top_level_reason)
      ReasonsForRejectionCountQuery::TOP_LEVEL_REASONS_TO_SUB_REASONS[top_level_reason.to_sym].to_s
    end

    def detail_reason_for(application_choice, top_level_reason)
      detail_questions = ReasonsForRejection::INITIAL_QUESTIONS[top_level_reason.to_sym].keys
      values_as_list(
        detail_questions.map { |detail_question| application_choice.structured_rejection_reasons[detail_question.to_s] }.compact,
      )
    end
  end
end
