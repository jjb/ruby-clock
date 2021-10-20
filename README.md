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
You can change this number with `RUBY_CLOCK_SHUTDOWN_WAIT_SECONDS` in the environment.

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

To use a file other than Clockfile for job definitions, specify it.
This will ignore Clockfile and only read jobs from clocks/MyClockfile:

    bundle exec clock clocks/MyClockfile

### Rails

Install the `clock` binstub and commit to your repo.

    bundle binstubs ruby-clock

To run your clock process in your app's environment:

    bundle exec rails runner bin/clock

To get smarter database connection management (such as in the case of a database restart or upgrade,
and maybe other benefits) and code reloading in dev (app code, not the code in Clockfile itself),
jobs are automatically wrapped in the
[rails app reloader](https://guides.rubyonrails.org/threading_and_code_execution.html).


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

You might have a main clock for general scheduled jobs, and then standalone ones
if your system has something where you want to monitor and adjust resources
for that work more precisely. Here, maybe the main clock needs a 2GB instance,
and the others each need 1GB all to themselves:

```
clock: bundle exec rails runner bin/clock
thing_checker: bundle exec rails runner bin/clock clocks/thing_checker.rb
thing_reporter: bundle exec rails runner bin/clock clocks/thing_reporter.rb
```

Because of this feature, do I regret using "Clockfile" instead of, say, "clock.rb"? Maybe.

#### Observing logs

Because STDOUT does not flush until a certain amount of data has gone into it,
you might not immediately see the ruby-clock startup message or job output if
viewing logs in a deployed environment such as Heroku where the logs are redirected
to another process or file. To change this behavior and have logs flush immediately,
add `$stdout.sync = true` to the top of your Clockfile.


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

### Shell commands

You can run shell commands in your jobs.

```ruby
schedule.every '1 day' do
  shell('sh scripts/process_stuff.sh')
end
```

By default they will be run with
[ruby backticks](https://livebook.manning.com/concept/ruby/backtick).
For better performance, install the [terrapin](https://github.com/thoughtbot/terrapin)
and [posix-spawn](https://github.com/rtomayko/posix-spawn) gems.

`shell` is a convenience method which just passes the string on.
If you want to use other terrapin features, you can skip the `shell` command
and use terrapin directly:

```ruby
schedule.every '1 day' do
  line = Terrapin::CommandLine.new('optimize_png', ":file")
  Organization.with_new_logos.find_each do |o|
    line.run(file: o.logo_file_path)
    o.update!(logo_optimized: true)
  end
end
```

#### shutdown behavior

Because of [this](https://stackoverflow.com/questions/69653842/),
if a shell job is running during shutdown, shutdown behavior seems to be changed
for _all_ running jobs - they no longer are allowed to finish within the timeout period.
Everything exits immediately.

Until this is figured out, if you are concerned about jobs exiting inelegantly,
you may want to run your shell jobs in their own sperate clock process, if possible.


### Rake tasks

You can run tasks from within the persistent runtime of ruby-clock, without
needing to shell out and start another process.

```ruby
schedule.every '1 day' do
  rake('reports:daily')
end
```

There is also `rake_execute` and `rake_async`. See [the code](https://github.com/jjb/ruby-clock/blob/main/lib/ruby-clock.rb)
and [this article](https://code.jjb.cc/running-rake-tasks-from-within-ruby-on-rails-code) for more info.

### Job Identifier

ruby-clock adds the `identifier` method to `Rufus::Scheduler::Job`. This method will return the job's
[name](https://github.com/jmettraux/rufus-scheduler/#name--string) if one was given.
If a name is not given, the last non-comment code line in the job's block
will be used instead. If for some reason an error is encountered while calculating this, the next
fallback is the line number of the job in Clockfile.

Some examples of jobs and their identifiers:

```ruby
schedule.every '1 second', name: 'my job' do
  Foo.bar
end
# => my job

schedule.every '1 day' do
  daily_things = Foo.setup_daily
  daily_things.process
  # TODO: figure out best time of day
end
# => daily_things.process

# n.b. ruby-clock isn't yet smart enough to remove trailing comments
schedule.every '1 week' do
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

## Syntax highlighting for Clockfile

To tell github and maybe other systems to syntax highlight Clockfile, put this in a .gitattributes file:

```gitattributes
Clockfile linguist-language=Ruby
```


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
