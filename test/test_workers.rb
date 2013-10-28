module VeryOwn
  class CustomException < StandardError; end
end

class RegularWorker
  include ::Sidekiq::Worker
end

class SingleExceptionWorker
  include ::Sidekiq::Worker
  sidekiq_options expected_failures: [ZeroDivisionError]
end

class MultipleExceptionWorker
  include ::Sidekiq::Worker
  sidekiq_options expected_failures: [NotImplementedError, VeryOwn::CustomException]
end
