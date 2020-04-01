module ProviderInterface
  class StatusBoxComponent < ActionView::Component::Base
    include ViewHelper

    attr_reader :application_choice

    def initialize(application_choice:, extra_arguments: {})
      @application_choice = application_choice
      @extra_arguments = extra_arguments
    end

    def application_status
      application_choice.status
    end

    def status_box_component_to_render
      "ProviderInterface::StatusBoxComponents::#{application_status.camelize}Component".constantize
    end

    # Should never happpen, but who knows
    class ComponentMismatchError < StandardError; end
  end
end
