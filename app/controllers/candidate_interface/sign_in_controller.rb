module CandidateInterface
  class SignInController < CandidateInterfaceController
    skip_before_action :authenticate_candidate!
    before_action :redirect_to_application_if_signed_in, except: %i[authenticate]

    def new
      candidate = Candidate.new
      render 'candidate_interface/sign_in/new', locals: { candidate: candidate }
    end

    def create
      SignInCandidate.new(candidate_params[:email_address], self).call
    end

    # This is where users land after clicking the magic link in their email. Because
    # some email clients preload links in emails, this is an extra step where
    # they click a button to confirm the sign in.
    def confirm_authentication
      authentication_token = AuthenticationToken.find_by_hashed_token(
        user_type: 'Candidate',
        raw_token: params[:token],
      )

      if authentication_token&.still_valid?
        Event.emit('Sign in confirmation page visit', candidate: candidate)
        render 'confirm_authentication'
      elsif authentication_token
        Event.emit('Sign in link expired', candidate: candidate)
        # If the token is expired, redirect the user to a page
        # with their token as a param where they can request
        # a new sign in email.
        redirect_to candidate_interface_expired_sign_in_path(token: params[:token], path: params[:path])
      else
        # TODO: When does this happen?
        redirect_to(action: :new)
      end
    end

    # After they click the confirm button, actually do the user sign in.
    def authenticate
      authentication_token = AuthenticationToken.find_by_hashed_token(
        user_type: 'Candidate',
        raw_token: params[:token],
      )

      if authentication_token.nil?
        Event.emit('Token not found')
        redirect_to(action: :new) and return
      elsif authentication_token.still_valid?
        candidate = authentication_token.user
        Event.emit('Successful sign in', candidate: candidate)
        flash[:success] = t('apply_from_find.account_created_message') if candidate.last_signed_in_at.nil?
        sign_in(candidate, scope: :candidate)
        add_identity_to_log(candidate.id)
        candidate.update!(last_signed_in_at: Time.zone.now)
        authentication_token.update!(used_at: Time.zone.now)

        redirect_to candidate_interface_interstitial_path(path: params[:path])
      else
        Event.emit('Sign in link expired', candidate: authentication_token.user)
        redirect_to candidate_interface_expired_sign_in_path(token: params[:token], path: params[:path])
      end
    end

    def expired
      authentication_token = AuthenticationToken.find_by_hashed_token(
        user_type: 'Candidate',
        raw_token: params[:token],
      )

      if authentication_token.blank?
        redirect_to candidate_interface_sign_in_path
      end
    end

    def create_from_expired_token
      authentication_token = AuthenticationToken.find_by_hashed_token(
        user_type: 'Candidate',
        raw_token: params[:token],
      )

      if authentication_token
        candidate = authentication_token.user
        CandidateInterface::RequestMagicLink.for_sign_in(candidate: candidate)
        add_identity_to_log candidate.id
        redirect_to candidate_interface_check_email_sign_in_path
      else
        render 'errors/not_found', status: :forbidden
      end
    end

  private

    def candidate_params
      params.require(:candidate).permit(:email_address)
    end
  end
end
