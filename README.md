# Sidekiq::ExpectedFailures

[![Code Climate](https://codeclimate.com/github/emq/sidekiq-expected_failures.png)](https://codeclimate.com/github/emq/sidekiq-expected_failures)
[![Build Status](https://travis-ci.org/emq/sidekiq-expected_failures.png?branch=master)](https://travis-ci.org/emq/sidekiq-expected_failures)
[![Coverage Status](https://coveralls.io/repos/emq/sidekiq-expected_failures/badge.png)](https://coveralls.io/r/emq/sidekiq-expected_failures)
[![Dependency Status](https://gemnasium.com/emq/sidekiq-expected_failures.png)](https://gemnasium.com/emq/sidekiq-expected_failures)
[![Gem Version](https://badge.fury.io/rb/sidekiq-expected_failures.png)](http://badge.fury.io/rb/sidekiq-expected_failures)

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
  sidekiq_options expected_failures: { Timeout::Error => nil } # handle that exception, but disable notification

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

You can pass a hash of exceptions to handle inside `sidekiq_options`. Each key-value pair may consist of:
- `exception => nil` - notifications disabled
- `exception => integer` - fires exception notify when x-th exception happens (on daily basis)
- `exception => [integer, integer]` - same as above but for each value

sidekiq-expected_failures utilizes sidekiq's [ExceptionHandler module][1] - so you might want to set some same limits for your exceptions and use Airbrake (for example) as a notification service to inform you that something bad is probably happing.

This is how web interface looks like:

![](img/interface.gif?raw=true)

It logs each failed jobs to to redis list (per day) and keep global counters (per exception class as a single redis hash). If you would like to get that counter as JSON response (for some external API usage for example) you can use path `expected_failures/stats`.

To activate naive filter/search (filters by exception, exception message or argument - simple contains case-insensitive match) press `F3` or `Cmd` / `Ctrl` + `F`.

### Default expected failures

You can configure defaults for all your workers (overridden completely by specifying `expected_failures` hash inside `sidekiq_options` - per worker).

``` ruby
Sidekiq.configure_server do |config|
  config.expected_failures = { ExceptionHandledByDefault => [1000, 2000] } # with notification enabled
end
```

### Usage with sidekiq-failures

Just be sure to load this one after `sidekiq-failures`, otherwise failed jobs will end up logged twice - and you probably don't want that.

If you want to load the web panel be sure to require `sidekiq/expected_failures/web` after `sidekiq/web`.

### Clearing failures

At the moment you have 3 public methods in `Sidekiq::ExpectedFailures` module:

- `clear_counters` - clears all counters (as I mentioned - it's stored inside single redis hash, but I doubt anyone would like to log more than 500 different exceptions, right?)
- `clear_old(days_ago)` - clears failed jobs older than days_ago days (this is 1 by default)
- `clear_all` - clears all failed jobs

This might change in the future to something more sane.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[1]: https://github.com/mperham/sidekiq/blob/master/lib/sidekiq/exception_handler.rb#L4
