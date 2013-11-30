Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "minitest/autorun"
require "minitest/spec"
require "minitest/mock"
require "minitest/pride"
require "mocha/setup"


require "timecop"
require "rack/test"

require "sidekiq"
require "sidekiq-expected_failures"
require "test_workers"

Sidekiq.logger.level = Logger::ERROR

REDIS = Sidekiq::RedisConnection.create(url: "redis://localhost/15", namespace: "sidekiq_expected_failures")

def redis(command, *args)
  Sidekiq.redis do |c|
    c.send(command, *args)
  end
end
