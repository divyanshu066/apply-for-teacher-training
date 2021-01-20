class HealthcheckController < ApplicationController
  def show; end

  def version
    render json: { version: ENV['SHA'] }
  end

  def health
    Rails.logger.info("Inside Health Check, with User-Agent: #{request.user_agent}")
    head :no_content
  end
end
