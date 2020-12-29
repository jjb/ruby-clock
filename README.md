# ruby-clock

ruby-clock is a [job scheduler](https://en.wikipedia.org/wiki/Job_scheduler),
known by heroku as a [clock process](https://devcenter.heroku.com/articles/scheduled-jobs-custom-clock-processes).
In many cases it can replace the use of cron.

This gem is very small with very few lines of code. For all its scheduling capabilities,
it relies on the venerable [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler/).
rufus-scheduler
[does not aim to be a standalone process or a cron replacement](https://github.com/jmettraux/rufus-scheduler/issues/307),
ruby-clock does.

Jobs are all run in their own parallel threads within the same process.

The clock process will respond to signals INT (^c at the command line) and
TERM (signal sent by environments such as Heroku and other PaaS's when shutting down).
In both cases, the clock will stop running jobs and give existing jobs 29 seconds
to stop before killing them.

## Installation

Add these lines to your application's Gemfile:

```ruby
gem 'ruby-clock'

# ruby-clock currently depends on rufus-scheduler master
git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }
gem 'rufus-scheduler', github: 'jmettraux/rufus-scheduler'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ruby-clock

## Usage

Write a file with your scheduled jobs in it, named Clockfile. The DSL and capabilities
are the same as those of [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler/).
Read the rufus-scheduler documentation to see what you can do.

```ruby
schedule.every('5 minutes') do
  UserDataReports.generate
end

# do something every day, five minutes after midnight
scheduler.cron '5 0 * * *' do
  DailyActivitySummary.generate_and_send
end
```

To start your clock process:

    bundle exec clock

### Rails

To run your clock process in your app's environment:

    bundle exec rails runner clock

### Non-Rails

Require your app's code at the top of Clockfile:

```ruby
require_relative './lib/app.rb'
schedule.every('5 minutes') do
...
```

### Heroku and other PaaS's

Add this line to your Procfile

```
clock: bundle exec rails runer clock
```

## More Config and Capabilities

### Error Handling

todo

### Callbacks

todo

### rufus-scheduler Options

All rufus-scheduler options are set to defaults. The `schedule` variable
Available in your Clockfile is and instance of `Rufus::Scheduler`,
so anything you can do on this instance, you can do in your Clockfile.

Perhaps in the future ruby-clock will add some easier specific configuration
capabilities for some things. Let me know if you have a request!


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
