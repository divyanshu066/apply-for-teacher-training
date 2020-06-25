module ProviderInterface
  class RejectionReasonsController < ProviderInterfaceController
    def new
      @application_choice = ApplicationChoice.find(params[:application_choice_id])
      @reasons_form = RejectionReasonsForm.new
    end

    def confirm
      @application_choice = ApplicationChoice.find(params[:application_choice_id])
      @reasons_form = RejectionReasonsForm.new(form_params)
      if @reasons_form.valid?
        if @reasons_form.additional_questions?
          render :additional_questions
        else
          render :confirm
        end
      else
        render :new
      end
    end

    def confirm_additional_questions
      @application_choice = ApplicationChoice.find(params[:application_choice_id])
      @reasons_form = RejectionReasonsForm.new(form_params)
      if @reasons_form.valid?
        render :confirm
      else
        render :additional_questions
      end
    end

    def create
      @application_choice = ApplicationChoice.find(params[:application_choice_id])
      @reasons_form = RejectionReasonsForm.new(form_params)
      @reject_application = RejectApplication.new(
        application_choice: @application_choice,
        rejection_reasons: @reasons_form.all_answered_questions,
      )

      if @reject_application.save
        flash[:success] = 'Application successfully rejected'
        redirect_to provider_interface_application_choice_path(
          application_choice_id: @application_choice.id,
        )
      else
        render action: :confirm
      end
    end

    def form_params
      params.require('provider_interface_rejection_reasons_form')
        .permit(*RejectionReasonsForm::FIELDS)
    end
  end
end
