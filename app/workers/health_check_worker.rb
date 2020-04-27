require 'http'

class HealthCheckWorker
  include Sidekiq::Worker

  def perform
    Rails.logger.info 'perform HealthCheckWorker'

    @health_check_url = ENV.fetch('APP_MONITORING_ENDPOINT')

    if @health_check_url.blank?
      Rails.logger.info 'health_check_url not present'
      raise 'health_check_url not present'
    end

    Rails.logger.info "APP_MONITORING_ENDPOINT  #{@health_check_url}"
    response = HTTP.get(@health_check_url)

    if response.status.success?
      Rails.logger.info 'Application is running...'
    else
      Rails.logger.info "Health check failed with status #{response.status}"
      raise "Application monitoring health check failed in #{ENV.fetch('HOSTING_ENVIRONMENT_NAME')}!"
    end
  end
end
