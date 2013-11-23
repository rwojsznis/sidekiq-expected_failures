module Sidekiq
  module ExpectedFailures
    class Middleware
      include Sidekiq::Util

      def call(worker, msg, queue)
        yield

        rescue *handled_exceptions(worker) => e
          data = {
            failed_at: Time.now.strftime("%Y/%m/%d %H:%M:%S %Z"),
            args:      msg['args'],
            exception: e.class.to_s,
            error:     e.message,
            worker:    msg['class'],
            processor: "#{hostname}:#{process_id}-#{Thread.current.object_id}",
            queue:     queue
          }

          log_exception(data)
      end

      private

        def handled_exceptions(worker)
          (Sidekiq.expected_failures || worker.class.get_sidekiq_options['expected_failures']).to_a
        end

        def log_exception(data)
          Sidekiq.redis do |conn|
            conn.multi do |m|
              m.lpush("expected:#{today}", Sidekiq.dump_json(data))
              m.sadd("expected:dates", today)
              m.hincrby("expected:count", data[:exception], 1)
            end
          end
        end

        def today
          Date.today.to_s
        end
    end
  end
end
