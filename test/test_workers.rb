module VeryOwn
  class CustomException < StandardError; end
end

class RegularWorker
  include ::Sidekiq::Worker
end

class SingleExceptionWorker
  include ::Sidekiq::Worker
  sidekiq_options expected_failures: { ZeroDivisionError => nil }
end

class MultipleExceptionWorker
  include ::Sidekiq::Worker
  sidekiq_options expected_failures: { NotImplementedError => nil, VeryOwn::CustomException => nil }
end

class CustomizedWorker
  include ::Sidekiq::Worker
  sidekiq_options expected_failures: {
    NotImplementedError      => nil,
    VeryOwn::CustomException => [10, 20, 50],
    ZeroDivisionError        => 5
  }
end
