require 'sinatra/assetpack'

module Sidekiq
  module ExpectedFailures
    module Web

      def self.registered(app)
        web_dir    = File.expand_path("../../../../web", __FILE__)
        assets_dir = File.join(web_dir, "assets")

        app.register Sinatra::AssetPack

        app.assets do
          serve '/js', from: assets_dir
          js 'expected',  ['/js/expected.js']
          js 'bootstrap', ['/js/bootstrap.js']
        end

        app.helpers do
          def link_to_details(job)
            data = []
            job["args"].each_with_index { |argument, index| data << "data-#{index+1}='#{h argument.inspect}'" }
            "<a href='#' #{data.join(' ')}>Details</a>"
          end
        end

        app.get "/expected_failures/clear/:what" do
          case params[:what]
          when 'old'
            Sidekiq::ExpectedFailures.clear_old
          when 'all'
            Sidekiq::ExpectedFailures.clear_all
          end

          redirect "#{root_path}expected_failures"
        end

        app.get "/expected_failures/?:date?" do
          @dates = Sidekiq::ExpectedFailures.dates
          @count = (params[:count] || 50).to_i

          if @dates
            @date = params[:date] || @dates.keys[0]
            (@current_page, @total_size, @jobs) = page("expected:#{@date}", params[:page], @count)
            @jobs = @jobs.map { |msg| Sidekiq.load_json(msg) }
            @counters = Sidekiq::ExpectedFailures.counters
          end

          erb File.read(File.join(web_dir, "views/expected_failures.erb"))
        end
      end
    end
  end
end
