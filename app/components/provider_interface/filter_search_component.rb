module ProviderInterface
  class FilterSearchComponent < ActionView::Component::Base
    include ViewHelper

    attr_reader :name, :type, :heading, :value

    def initialize(name:, type:, heading:, value:)
      @name = name
      @type = type
      @heading = heading
      @value = value
    end
  end
end