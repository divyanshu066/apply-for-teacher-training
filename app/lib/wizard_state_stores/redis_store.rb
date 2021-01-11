require 'redis'

module WizardStateStores
  class RedisStore
    def initialize(key:)
      @redis = ApplyRedisConnection.current
      @key = key
    end

    def write(value)
      @redis.set(@key, value, ex: ActiveSupport::Duration::SECONDS_PER_DAY)
    end

    def read
      @redis.get(@key)
    end

    def delete
      @redis.del(@key)
    end
  end
end
