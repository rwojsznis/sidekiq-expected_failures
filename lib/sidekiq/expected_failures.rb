require "sidekiq/expected_failures/version"
require "sidekiq/expected_failures/middleware"
require "sidekiq/expected_failures/web"

module Sidekiq

  def self.expected_failures=(exceptions)
    @expected_failures = exceptions
  end

  def self.expected_failures
    @expected_failures || {}
  end

  module ExpectedFailures

    def self.dates
      Sidekiq.redis do |c|
        c.smembers "expected:dates"
      end.sort.reverse.each_with_object({}) do |d, hash|
        hash[d] = Sidekiq.redis { |c| c.llen("expected:#{d}") }
      end
    end

    def self.counters
      Sidekiq.redis { |r| r.hgetall("expected:count") }
    end

    def self.clear_all
      clear(dates.keys)
    end

    def self.clear_old(days_ago = 1)
      range = dates.keys.delete_if { |d| Date.parse(d) > Date.today.prev_day(days_ago) }
      clear(range)
    end

    def self.clear_counters
      Sidekiq.redis { |r| r.del("expected:count") }
    end

    private

      def self.clear(dates)
        dates.each do |date|
          Sidekiq.redis do |c|
            c.multi do |m|
              m.srem("expected:dates", date)
              m.del("expected:#{date}")
            end
          end
        end
      end
  end
end

if defined?(Sidekiq::Web)
  Sidekiq::Web.register Sidekiq::ExpectedFailures::Web
  Sidekiq::Web.tabs["Expected Failures"] = "expected_failures"
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::ExpectedFailures::Middleware
  end
end
