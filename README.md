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
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ruby-clock

## Usage

Create a file named Clockfile. This will hold your job definitions.
The DSL and capabilities
are the same as those of [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler/).
Read the rufus-scheduler documentation to see what you can do.

```ruby
schedule.every('5 minutes') do
  UserDataReports.generate
end

# do something every day, five minutes after midnight
schedule.cron '5 0 * * *' do
  DailyActivitySummary.generate_and_send
end
```

To start your clock process:

    bundle exec clock

### Rails

Install the `clock` binstub and commit to your repo.

    bundle binstubs ruby-clock

To run your clock process in your app's environment:

    bundle exec rails runner bin/clock

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
clock: bundle exec rails runner bin/clock
```

## More Config and Capabilities

### Error Handling

You can catch and report errors raised in your jobs by defining an error catcher at
the top of your Clockfile like this:

```ruby
def schedule.on_error(job, error)
  ErrorReporter.track_exception(error)
end
```

### Callbacks

You can define before, after, and around callbacks which will run for all jobs.
Read [the rufus-scheduler documentation](https://github.com/jmettraux/rufus-scheduler/#callbacks)
to learn how to do this. Where the documentation references `s`, you should use `schedule`.

### Job Identifier

ruby-clock adds the `identifier` method to `Rufus::Scheduler::Job`. This method will return the job's
[name](https://github.com/jmettraux/rufus-scheduler/#name--string) if one was given.
If a name is not given, the last non-comment code line in the job's block
will be used instead. If for some reason an error is encountered while calculating this, the next
fallback is the line number of the job in Clockfile.

Some examples of jobs and their identifiers:

```ruby
schedule.every '1 second', name: 'my job' do |variable|
  Foo.bar
end
# => my job

schedule.every '1 day' do |variable|
  daily_things = Foo.setup_daily
  daily_things.process
  # TODO: figure out best time of day
end
# => daily_things.process

# n.b. ruby-clock isn't yet smart enough to remove trailing comments
schedule.every '1 week' do |variable|
  weekly_things = Foo.setup_weekly
  weekly_things.process # does this work???!1~
end
# => weekly_things.process # does this work???!1~
```

This can be used for keeping track of job behavior in logs or a
stats tracker. For example:

```ruby
def schedule.on_post_trigger(job, trigger_time)
  duration = Time.now-trigger_time.to_t
  StatsTracker.value('Clock: Job Execution Time', duration.round(2))
  StatsTracker.value("Clock: Job #{job.identifier} Execution Time", duration.round(2))
  StatsTracker.increment('Clock: Job Executions')
end

schedule.every '10 seconds', name: 'thread stats' do
  thread_usage = Hash.new(0)
  schedule.work_threads(:active).each do |t|
    thread_usage[t[:rufus_scheduler_job].identifier] += 1
  end
  thread_usage.each do |job, count|
    StatsTracker.value("Clock: Job #{job} Active Threads", count)
  end

  StatsTracker.value("Clock: Active Threads", schedule.work_threads(:active).size)
  StatsTracker.value("Clock: Vacant Threads", schedule.work_threads(:vacant).size)
  StatsTracker.value("Clock: DB Pool Size", ActiveRecord::Base.connection_pool.connections.size)
end
```

### other rufus-scheduler Options

All rufus-scheduler options are set to defaults. The `schedule` variable
available in your Clockfile is an instance of `Rufus::Scheduler`,
so anything you can do on this instance, you can do in your Clockfile.

Perhaps in the future ruby-clock will add some easier specific configuration
capabilities for some things. Let me know if you have a request!


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
