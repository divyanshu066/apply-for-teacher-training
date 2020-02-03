class ProviderMailer < ApplicationMailer
  def account_created(provider_user)
    @provider_user = provider_user

    view_mail(
      GENERIC_NOTIFY_TEMPLATE,
      to: @provider_user.email_address,
      subject: t('provider_account_created.email.subject'),
    )
  end

  def application_submitted(provider_user, application_choice)
    @application =
      Struct.new(
        :course_name_and_code,
        :provider_user_name,
        :candidate_name,
        :application_choice_id,
      ).new(
        application_choice.course.name_and_code,
        provider_user.full_name,
        application_choice.application_form.full_name,
        application_choice.id,
    )

    view_mail(GENERIC_NOTIFY_TEMPLATE,
              to: provider_user.email_address,
              subject: t('provider_application_submitted.email.subject', course_name_and_code: @application.course_name_and_code))
  end

  def application_rejected_by_default(provider_user, application_choice)
    @application =
      Struct.new(
        :candidate_name,
        :provider_user_name,
        :course_name_and_code,
        :submitted_at,
        :application_choice,
      ).new(
        application_choice.application_form.full_name,
        provider_user.full_name,
        application_choice.course.name_and_code,
        application_choice.application_form.submitted_at.to_s(:govuk_date).strip,
        application_choice,
    )

    view_mail(GENERIC_NOTIFY_TEMPLATE,
              to: provider_user.email_address,
              subject: t('provider_application_rejected_by_default.email.subject', candidate_name: @application.candidate_name))
  end
end
