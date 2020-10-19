module CandidateInterface
  class PrefillApplicationController < CandidateInterfaceController

    def new; end # render the radio buttons

    def create
      # validate radio button present etc

      current_candidate
      current_candidate.current_application

      # interesting bit
      if prefilling
        prefill
        set flash "we prefilled yr appln"
        redirect to application
      else
        redirect to before_you_start_path
      end
    end
  end
end
