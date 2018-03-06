# Sample 'app' so you can easily test/tweak visual/ui aspects
# Run with: rackup config.ru; assumes redis is up and running
# on default port and produces some junk on each run
require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-expected_failures'
require 'sidekiq/expected_failures/web'

12.times do |i|
  Sidekiq.redis do |c|
    date = Time.now.strftime("%Y-%m-#{"%02d" % (i + 1)}")
    100.times do
      data = {
        failed_at: Time.now.strftime("%Y/%m/#{"%02d" % (i + 1)} %H:%M:%S %Z"),
        args:      [{ "hash" => "options", "more" => "options" }, 123],
        exception: ["ArgumentError", "Custom::Error"].sample,
        error:     ["Some error message", "Custom exception msg"].sample,
        worker:    ["HardWorker", "OtherWorker", "WelcomeMailer"].sample,
        queue:     ["api_calls", "other_queue", "mailer"].sample
      }
      c.lpush("expected:#{date}", Sidekiq.dump_json(data))
    end
    c.sadd("expected:dates", "#{date}")
    c.hincrby("expected:count", "StandardError", rand(100))
    c.hincrby("expected:count", "Custom::Error", rand(100))
  end
end

run Sidekiq::Web
