require 'http'

class HealthCheckWorker
  include Sidekiq::Worker

  def perform
    Rails.logger.info 'perform HealthCheckWorker'

    @health_check_url = ENV['APP_MONITORING_ENDPOINT']

    if @health_check_url.blank?
      Rails.logger.info 'health_check_url not present'
      raise 'health_check_url not present'
    end

    Rails.logger.info "APP_MONITORING_ENDPOINT  #{@health_check_url}"
    response = HTTP.get(@health_check_url)
    Rails.logger.info 'Application is running...' if response.status.success?
  end
end
