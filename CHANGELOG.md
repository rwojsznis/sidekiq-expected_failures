## 0.2.0

- removed `sinatra-assetpack` dependency - js assets are now served inline
  (it seemed like a overkill to include that gem just for just two files)

- added option to configure exception handled by default (for all workers):

``` ruby
  Sidekiq.configure_server do |config|
    config.expected_failures = [AlwaysHandledExceptionByDefault]
  end
```

Note: if you specify `expected_failure`s for given worker defaults will be
discarded (for that worker).

## 0.0.1

- Initial release
