## 0.2.5

- add csrf tag for sidekiq >= 3.4.2
- **[BREAKING CHANGE]** don't load `sidekiq/web` automagically at
  all (it never made any sense), instead do something like:

``` ruby
require 'sidekiq/web'
# then load expected failures panel
require 'sidekiq/expected_failures/web'
```

## 0.2.4

- `Sidekiq::ExpectedFailures.clear_old` can now accept argument - will remove failures
  that are n days old (1 by default) - useful if you want to clear some of old failures
  using cronjob

## 0.2.3

- removed (unnecessary) dependency on `Sidekiq::Util` (now Sidekiq 3.0 compatible)

## 0.2.2

- rescue load error of `sidekiq/web` (this allows client only usage)

## 0.2.1

- added JSON stats path in case you would like to fetch this data from external service.
  It works similar to sidekiq's _stats_. You can visit: `expected_failures/stats` to
  get a JSON response with global counters (PR #4)

``` json
  {

    "failures": {
        "ExceptionName": "123",
        "Other::ExceptionName": "10",
    }

}
```

## 0.2.0

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
