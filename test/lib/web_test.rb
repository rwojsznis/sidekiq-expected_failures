require "test_helper"
require "sidekiq/web"

module Sidekiq
  describe "WebExtension" do
    include Rack::Test::Methods

    def app
      Sidekiq::Web
    end

    def failed_count
      Sidekiq.redis { |c| c.get("stat:failed") }
    end

    def create_sample_counter
      redis("hset", "expected:count", "StandardError", 5)
      redis("hset", "expected:count", "Custom::Error", 10)
    end

    def create_sample_failure
      data = {
        failed_at: Time.now.strftime("%Y/%m/%d %H:%M:%S %Z"),
        args:      [{"hash" => "options", "more" => "options"}, 123],
        exception: "ArgumentError",
        error:     "Some error message",
        worker:    "HardWorker",
        queue:     "api_calls"
      }

      Sidekiq.redis do |c|
        c.lpush("expected:2013-09-10", Sidekiq.dump_json(data))
        c.sadd("expected:dates", "2013-09-10")
      end

      Sidekiq.redis do |c|
        c.lpush("expected:2013-09-09", Sidekiq.dump_json(data))
        c.sadd("expected:dates", "2013-09-09")
      end
    end

    before do
      Sidekiq.redis = REDIS
      Sidekiq.redis {|c| c.flushdb }
      Timecop.freeze(Time.local(2013, 9, 10))
    end

    after { Timecop.return }

    it 'can display home with failures tab' do
      get '/'
      last_response.status.must_equal(200)
      last_response.body.must_match(/Sidekiq/)
      last_response.body.must_match(/Expected Failures/)
    end

    it 'can display failures page without any failures' do
      get '/expected_failures'
      last_response.status.must_equal(200)
      last_response.body.must_match(/Expected Failures/)
      last_response.body.must_match(/No failed jobs found/)
    end

    describe 'when there are failures' do
      before do
        create_sample_failure
        get '/expected_failures'
      end

      it 'should be successful' do
        last_response.status.must_equal(200)
      end

      it 'lists failed jobs' do
        last_response.body.must_match(/HardWorker/)
        last_response.body.must_match(/api_calls/)
      end

      it 'can remove all failed jobs' do
        get '/expected_failures'
        last_response.body.must_match(/HardWorker/)

        post '/expected_failures/clear', { what: 'all' }
        last_response.status.must_equal(302)
        last_response.location.must_match(/expected_failures$/)

        get '/expected_failures'
        last_response.body.must_match(/No failed jobs found/)
      end

      it 'can remove failed jobs older than 1 day' do
        get '/expected_failures'
        last_response.body.must_match(/2013-09-10/)
        last_response.body.must_match(/2013-09-09/)

        post '/expected_failures/clear', { what: 'old' }
        last_response.status.must_equal(302)
        last_response.location.must_match(/expected_failures$/)

        get '/expected_failures'
        last_response.body.wont_match(/2013-09-09/)
        last_response.body.must_match(/2013-09-10/)

        assert_nil redis("get", "expected:2013-09-09")
      end
    end

    describe 'counter' do
      describe 'when empty' do
        it 'does not display counter div' do
          create_sample_failure
          get '/expected_failures'
          last_response.body.wont_match(/dl-horizontal/)
          last_response.body.wont_match(/All counters/i)
        end
      end

      describe 'when not empty' do
        before { create_sample_counter }

        it 'displays counters' do
          get '/expected_failures'
          last_response.body.must_match(/dl-horizontal/)
          last_response.body.must_match(/All counters/i)
        end

        it 'can clear counters' do
          get '/expected_failures'
          last_response.body.must_match(/Custom::Error/)

          post '/expected_failures/clear', { what: 'counters' }
          last_response.status.must_equal(302)
          last_response.location.must_match(/expected_failures$/)

          get '/expected_failures'
          last_response.body.wont_match(/Custom::Error/)

          assert_nil redis("get", "expected:count")
        end
      end
    end
  end
end
