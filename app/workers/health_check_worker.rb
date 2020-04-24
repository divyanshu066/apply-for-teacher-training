require 'http'

class HealthCheckWorker
  include Sidekiq::Worker

  def perform
    Rails.logger.info 'perform HealthCheckWorker'

    @healthCheckUrl = ENV['APP_MONITORING_ENDPOINT']

    unless @healthCheckUrl.present?
      Rails.logger.info '@healthCheckUrl not present'
      raise '@healthCheckUrl not present'
    end
    
    Rails.logger.info "APP_MONITORING_ENDPOINT  #{@healthCheckUrl}"
    response = HTTP.get(@healthCheckUrl)
    Rails.logger.info 'Application is running...' if response.status.success?
  end
end
