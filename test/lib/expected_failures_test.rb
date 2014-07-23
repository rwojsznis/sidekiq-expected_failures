require "test_helper"

module Sidekiq
  module ExpectedFailures
    describe "clear_old (helper method)" do
      before do
        Sidekiq.redis = REDIS
        Sidekiq.redis {|c| c.flushdb }
        Timecop.freeze(Time.local(2014, 6, 10))

        # fresh failure
        Sidekiq.redis do |c|
          c.lpush("expected:2014-06-10", Sidekiq.dump_json({}))
          c.sadd("expected:dates", "2014-06-10")
        end

        # 1 day old
        Sidekiq.redis do |c|
          c.lpush("expected:2014-06-09", Sidekiq.dump_json({}))
          c.sadd("expected:dates", "2014-06-09")
        end

        # 3 days old
        Sidekiq.redis do |c|
          c.lpush("expected:2014-06-07", Sidekiq.dump_json({}))
          c.sadd("expected:dates", "2014-06-07")
        end
      end

      after do
        Timecop.return
      end

      it "clears failures older than 1 day by default" do
        Sidekiq::ExpectedFailures.clear_old
        assert_equal ["2014-06-10"], redis("smembers", "expected:dates")
        assert_nil redis("get", "expected:2014-06-09")
        assert_nil redis("get", "expected:2014-06-07")
      end

      it "can be called with days_old argument" do
        Sidekiq::ExpectedFailures.clear_old(2)
        assert_equal ["2014-06-09", "2014-06-10"], redis("smembers", "expected:dates").sort
      end
    end
  end
end
