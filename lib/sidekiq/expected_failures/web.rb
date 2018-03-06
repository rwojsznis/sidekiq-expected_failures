module Sidekiq
  module ExpectedFailures
    module Web
      def self.registered(app)
        web_dir = File.expand_path("../../../../web", __FILE__)

        app.helpers do
          def link_to_details(job)
            data = []
            search = ""
            job["args"].each_with_index do |argument, index|
              data << "data-#{index+1}='#{h argument.inspect}'"
              search << h(argument.inspect)
            end
            "<a href='#' data-search='#{search.downcase}' #{data.join(' ')} title='#{job["worker"]}'>Details</a>"
          end
        end

        app.post "/expected_failures/clear" do
          if %w(old all counters).include?(params[:what])
            Sidekiq::ExpectedFailures.send("clear_#{params[:what]}")
          end

          redirect "#{root_path}expected_failures"
        end

        app.get "/expected_failures/stats" do
          json(failures: Sidekiq::ExpectedFailures.counters)
        end

        panel = proc do
          @dates = Sidekiq::ExpectedFailures.dates
          @count = (params[:count] || 50).to_i

          if @dates
            @date = params[:date] || @dates.keys[0]
            (@current_page, @total_size, @jobs) = page("expected:#{@date}", params[:page], @count)
            @jobs = @jobs.map { |msg| Sidekiq.load_json(msg) }
            @counters = Sidekiq::ExpectedFailures.counters
          end

          @javascript = %w(expected bootstrap).map do |file|
            File.read(File.join(web_dir, "assets/#{file}.js"))
          end.join

          erb File.read(File.join(web_dir, "views/expected_failures.erb"))
        end

        app.get "/expected_failures/day/:date" do
          self.instance_exec(&panel)
        end

        app.get "/expected_failures" do
          self.instance_exec(&panel)
        end
      end
    end
  end
end

Sidekiq::Web.register Sidekiq::ExpectedFailures::Web
Sidekiq::Web.tabs["Expected Failures"] = "expected_failures"
