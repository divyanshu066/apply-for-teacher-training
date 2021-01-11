module ProviderInterface
  class InterviewsController < ProviderInterfaceController
    before_action :set_application_choice
    def new
      @new_interview_form = NewInterviewForm.new
    end

    def create
      #  Create the interview
    end

    def check
      #  Check answers
    end

    def has_multiple_interviewer_options?
      application_choice.accredited_provider.present? && current_provider_user.provider_permissions.make_decisions.exists?(provider: provider) && current_provider_user.provider_permissions.make_decisions.exists?(provider: accredited_provider)
    end

    def show_organisations_user_has_permissions_for
      
    end
  end
end
