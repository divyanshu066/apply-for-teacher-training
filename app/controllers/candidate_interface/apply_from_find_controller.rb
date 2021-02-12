module CandidateInterface
  # The Apply from Find page is the landing page for candidates coming from the
  # Find postgraduate teacher training (https://www.find-postgraduate-teacher-training.service.gov.uk/)
  class ApplyFromFindController < CandidateInterfaceController
    skip_before_action :authenticate_candidate!

    rescue_from ActionController::ParameterMissing, with: :render_not_found

    def show
      set_service_and_course(params[:providerCode], params[:courseCode])

      if @service.can_apply_on_apply? && current_candidate.present?
        current_candidate.update!(course_from_find_id: @course.id)

        redirect_to candidate_interface_interstitial_path
      elsif @provider&.not_accepting_appplications_on_ucas?
        redirect_to candidate_interface_create_account_or_sign_in_path(
          providerCode: @provider.code,
          courseCode: @course.code,
        )
      elsif @service.can_apply_on_apply?
        @apply_on_ucas_or_apply = CandidateInterface::ApplyOnUCASOrApplyForm.new(
          provider_code: params[:providerCode], course_code: params[:courseCode],
        )

        render :apply_on_ucas_or_apply
      elsif @service.course_on_find?
        render :apply_on_ucas_only
      else
        render_not_found
      end
    end

    def ucas_or_apply
      @apply_on_ucas_or_apply = CandidateInterface::ApplyOnUCASOrApplyForm.new(apply_on_ucas_or_apply_params)

      set_service_and_course(@apply_on_ucas_or_apply.provider_code, @apply_on_ucas_or_apply.course_code)

      if @apply_on_ucas_or_apply.valid?
        if @apply_on_ucas_or_apply.apply?
          redirect_to candidate_interface_create_account_or_sign_in_path(
            providerCode: @apply_on_ucas_or_apply.provider_code,
            courseCode: @apply_on_ucas_or_apply.course_code,
          )
        else
          redirect_to candidate_interface_apply_with_ucas_interstitial_path(
            candidate_interface_apply_on_ucas_or_apply_form: {
              provider_code: @apply_on_ucas_or_apply.provider_code,
              course_code: @apply_on_ucas_or_apply.course_code,
            },
          )
        end
      else
        render :apply_on_ucas_or_apply
      end
    end

    def ucas_interstitial
      @apply_on_ucas_or_apply = CandidateInterface::ApplyOnUCASOrApplyForm.new(
        apply_on_ucas_or_apply_params.merge(service: 'ucas'),
      )

      set_service_and_course(@apply_on_ucas_or_apply.provider_code, @apply_on_ucas_or_apply.course_code)
    end

    def apply_with_ucas
      redirect_to UCAS.apply_url
    end

  private

    def set_service_and_course(provider_code, course_code)
      @service = ApplyFromFindPage.new(provider_code: provider_code, course_code: course_code)
      @service.determine_whether_course_is_on_find_or_apply
      @course = @service.course
      @provider = @service.provider
    end

    def render_not_found
      render :not_found, status: :not_found
    end

    def apply_on_ucas_or_apply_params
      params.require(:candidate_interface_apply_on_ucas_or_apply_form)
        .permit(:service, :provider_code, :course_code)
    end
  end
end
