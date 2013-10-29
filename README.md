# Sidekiq::ExpectedFailures

If you don't rely on standard sidekiq's retry behavior and you want to track exceptions, that will happen one way, or another - this thing is for you.

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-expected_failures'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-expected_failures

## Usage

Let's say you do a lot of API requests to some not reliable reliable service. Inside your worker you handle `Timeout::Error` exception - you delay it's execution, maybe modify parameters somehow, it doesn't really matter, what matter is that you want to log that it happen in a convenient way. Describe that case using ruby:

``` ruby
class ApiCallWorker
  include ::Sidekiq::Worker
  sidekiq_options expected_failures: [Timeout::Error]

  def perform(arguments)
    # do some work
    # ...

    # this service sucks, try again in 10 minutes
    rescue Timeout::Error => e
      Sidekiq::Client.enqueue_in(10.minutes, self.class, arguments)
      raise e # this will be handled by sidekiq-expected_failures middleware

    # ensure block or some other stuff
    # ...
  end
```

You can pass array of exceptions to handle inside `sidekiq_options`. This is how web interface looks like:

![](http://i.imgur.com/7Fe8voD.jpg)

It logs each failed jobs to to redis list (per day) and keep global counters (per exception class as a single redis hash).

### Usage with sidekiq-failures

Just be sure to load this one after `sidekiq-failures`, otherwise failed jobs will end up logged twice - and you probably don't want that.

### Clearing failures

At the moment you have 3 public methods in `Sidekiq::ExpectedFailures` module:

- `clear_counters` - clears all counters (as I mentioned - it's stored inside single redis hash, but I doubt anyone would like to log more than 500 different exceptions, right?)
- `clear_old` - clears failed jobs older than today
- `clear_all` - clears all failed jobs

This might change in the future to something more sane.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
