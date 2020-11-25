module SupportInterface
  class CandidatesFilter
    attr_reader :applied_filters

    def initialize(params:)
      @applied_filters = params
    end

    def filters
      [
        {
          type: :search,
          heading: 'Email',
          value: applied_filters[:q],
          name: 'q',
        },
        {
          type: :search,
          heading: 'Candidate number',
          value: applied_filters[:candidate_number],
          name: 'candidate_number',
        },
      ]
    end
  end
end
