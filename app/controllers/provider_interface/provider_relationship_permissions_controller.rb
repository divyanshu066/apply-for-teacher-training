module ProviderInterface
  class ProviderRelationshipPermissionsController < ProviderInterfaceController
    before_action :render_403_unless_access_permitted

    def edit
      @form = ProviderRelationshipPermissionsForm.new(permissions_model: permissions_model)
    end

    def update
      @form = ProviderRelationshipPermissionsForm.new(
        permission_params.merge(permissions_model: permissions_model),
      )

      if @form.valid?
        @form.update!
        flash[:success] = 'Permissions successfully changed'
        redirect_to provider_interface_organisation_path(permissions_model.training_provider)
      else
        flash[:warning] = 'Unable to save permissions, please try again. If problems persist please contact support.'
        render :edit
      end
    end

  private

    def permissions_model
      ProviderRelationshipPermissions.find_by!(
        training_provider_id: params[:training_provider_id],
        ratifying_provider_id: params[:ratifying_provider_id],
      )
    end

    def permission_params
      params.require(:provider_interface_provider_relationship_permissions_form)
        .permit(make_decisions: [], view_safeguarding_information: []).to_h
    end

    def render_403_unless_access_permitted
      # training_provider = provider_relationship_permissions.training_provider
      #
      # render_403 unless ProviderAuthorisation.new(actor: current_provider_user)
      #   .can_manage_organisation?(provider: training_provider)
    end
  end

  class ProviderRelationshipPermissionsForm
    include ActiveModel::Model

    attr_accessor :permissions_model, :make_decisions, :view_safeguarding_information
    delegate :training_provider, :ratifying_provider, to: :permissions_model

    validate :at_least_one_active_permission_in_pair

    def initialize(attrs)
      super(attrs)

      @make_decisions ||= providers_currently_having_permission_to('make_decisions')
      @view_safeguarding_information ||= providers_currently_having_permission_to('view_safeguarding_information')
    end

    def update!
      @permissions_model.assign_attributes(permissions_attributes_for_persistence)

      if @permissions_model.valid?
        @permissions_model.save!
      end
    end

  private

    def permissions_attributes_for_persistence
      %w[training ratifying].reduce({}) do |hash, role|
        hash.merge({
          "#{role}_provider_can_make_decisions" => @make_decisions.include?(role),
          "#{role}_provider_can_view_safeguarding_information" => @view_safeguarding_information.include?(role),
        })
      end
    end

    def providers_currently_having_permission_to(permission)
      %w[training ratifying].reduce([]) do |list, role|
        if @permissions_model.send("#{role}_provider_can_#{permission}?")
          list.push role
        end

        list
      end
    end

    def at_least_one_active_permission_in_pair
      %i[make_decisions view_safeguarding_information].each do |permission|
        if send(permission).reject(&:blank?).none?
          errors.add(permission, 'Must have one')
        end
      end
    end
  end
end
