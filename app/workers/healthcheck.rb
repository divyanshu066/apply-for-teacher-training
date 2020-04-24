class ClockworkCheck
  include Sidekiq::Worker

  def perform(*)
    Rails.logger.info ENV['APP_MONITORING_ENDPOINT']
    response = HTTP.get(ENV['APP_MONITORING_ENDPOINT'])
    Rails.logger.info 'Application is running...' if response.status.success?
  end
end
