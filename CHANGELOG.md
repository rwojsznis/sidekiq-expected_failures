## 0.2.0 (in progress)

- [**breaking change**] ability to use Sidekiq's build-in `handle_exception`
  method - in case you want to use airbrake or other exception notify service.
  Since version `0.2.0` you need to provide  `expected_failures` in a form of
  a hash, for example:

``` ruby
class CustomizedWorker
  include ::Sidekiq::Worker
  sidekiq_options expected_failures: {
    NotImplementedError      => nil,          # notification disabled
    VeryOwn::CustomException => [10, 20, 50], # notify on 10th, 20th, 50th failure
    ZeroDivisionError        => 5             # notify on 5th failure
  }
end
```

- removed `sinatra-assetpack` dependency - js assets are now served inline
  (it seemed like a overkill to include that gem just for just two files)

- added option to configure exception handled by default (for all workers):

``` ruby
  Sidekiq.configure_server do |config|
    config.expected_failures = { AlwaysHandledExceptionByDefault => 1000 }
  end
```

Note: if you specify `expected_failure`s for given worker defaults will be
discarded (for that worker).

- small front-end adjustments

## 0.0.1

- Initial release
