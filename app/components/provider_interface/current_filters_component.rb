module ProviderInterface
  class CurrentFiltersComponent < ViewComponent::Base
    include ViewHelper

    attr_reader :page_state
    delegate :available_filters, :filter_selections, to: :page_state

    def initialize(page_state:)
      @page_state = page_state
    end

    def build_tag_url_query_params(heading:, tag_value:)
      tag_applied_filters = filter_selections.clone
      tag_applied_filters[heading] = filter_selections[heading].except(tag_value)
      tag_applied_filters
    end

    def retrieve_tag_text(heading, lookup_val)
      if heading.eql?('search')
        filter_selections[:search][:candidates_name]
      else
        available_filters.each do |available_filter|
          if available_filter.key(heading)
            available_filter[:input_config].each do |input_config|
              return input_config[:text].to_s if input_config.key(lookup_val)
            end
          end
        end
      end
    end
  end
end
