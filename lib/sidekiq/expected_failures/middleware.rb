module Sidekiq
  module ExpectedFailures
    class Middleware
      include Sidekiq::Util

      attr_reader :handled_exceptions

      def call(worker, msg, queue)
        setup_exceptions(worker)

        yield

        rescue *handled_exceptions.keys => ex
          data = {
            failed_at: Time.now.strftime("%Y/%m/%d %H:%M:%S %Z"),
            args:      msg['args'],
            exception: ex.class.to_s,
            error:     ex.message,
            worker:    msg['class'],
            processor: "#{hostname}:#{process_id}-#{Thread.current.object_id}",
            queue:     queue
          }

          log_exception(data, ex, msg)
      end

      private

        def setup_exceptions(worker)
          @handled_exceptions = worker.class.get_sidekiq_options['expected_failures'] || Sidekiq.expected_failures
        end

        def exception_intervals(ex)
          [handled_exceptions[ex.class]].flatten.compact
        end

        def log_exception(data, ex, msg)
          result = Sidekiq.redis do |conn|
            conn.multi do |m|
              m.lpush("expected:#{today}", Sidekiq.dump_json(data))
              m.sadd("expected:dates", today)
              m.hincrby("expected:count", data[:exception], 1)
            end
          end

          handle_exception(ex, msg) if exception_intervals(ex).include?(result[0])
        end

        def today
          Date.today.to_s
        end
    end
  end
end
