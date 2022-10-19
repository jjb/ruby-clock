THESE ARE THE DOCS FOR VERSION 2.0.0.beta

See version 1 docs here: https://github.com/jjb/ruby-clock/tree/v1.0.0

# ruby-clock

ruby-clock is a [job scheduler](https://en.wikipedia.org/wiki/Job_scheduler),
known by heroku as a [clock process](https://devcenter.heroku.com/articles/scheduled-jobs-custom-clock-processes).
In many cases it can replace the use of cron.

Why another ruby scheduler project? See
[this feature matrix of the space](https://docs.google.com/spreadsheets/d/148VMKY9iyOyUASYytSGiUJKvH0-O5Ri-3Cwr3S6DRPU/edit?usp=sharing).
Feel free to leave a comment with suggestions for changes or additions.

This gem is very small with very few lines of code. For all its scheduling capabilities,
it relies on the venerable [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler/).
rufus-scheduler
[does not aim to be a standalone process or a cron replacement](https://github.com/jmettraux/rufus-scheduler/issues/307),
ruby-clock does.

Jobs are all run in their own parallel threads within the same process.

The clock process will respond to signals `INT` (<kbd>^c</kbd> at the command line) and
`TERM` (signal sent by environments such as Heroku and other PaaS's when shutting down).
In both cases, the clock will stop running jobs and give existing jobs 29 seconds
to stop before killing them.
You can change this number with `RUBY_CLOCK_SHUTDOWN_WAIT_SECONDS` in the environment.

## Installation

ruby >= 2.7 is required.

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
Define jobs like this:

```ruby
every('5 minutes') do
  UserDataReports.generate
end

# do something every day, five minutes after midnight
cron '5 0 * * *' do
  DailyActivitySummary.generate_and_send
end
```

To start your clock process:

    bundle exec clock

To use a file other than Clockfile for job definitions, specify it.
This will ignore Clockfile and only read jobs from clocks/MyClockfile:

    bundle exec clock clocks/MyClockfile

### Rails

To run your clock process in your app's environment:

    bundle exec clock

To get smarter database connection management (such as in the case of a database restart or upgrade,
and maybe other benefits) and code reloading in dev (app code, not the code in Clockfile itself),
jobs are automatically wrapped in the
[rails app reloader](https://guides.rubyonrails.org/threading_and_code_execution.html).
This [may incur a performance impact for certain jobs](https://github.com/rails/rails/issues/43504),
I'm still exploring this.


#### ActiveRecord Query Cache

You may wish to
[turn off the ActiveRecord Query Cache](https://code.jjb.cc/turning-off-activerecord-query-cache-to-improve-memory-consumption-in-background-jobs)
for your jobs. You can do so with the around trigger:

```ruby
around_action(job_proc)
  ActiveRecord::Base.uncached do
    job_proc.call
  end
end
```

### Non-Rails

Require your app's code at the top of Clockfile:

```ruby
require_relative './lib/app.rb'
every('5 minutes') do
...
```

### Heroku and other PaaS's

Add this line to your Procfile

```
clock: bundle exec clock
```

You might have a main clock for general scheduled jobs, and then standalone ones
if your system has something where you want to monitor and adjust resources
for that work more precisely. Here, maybe the main clock needs a 2GB instance,
and the others each need 1GB all to themselves:

```
clock: bundle exec clock
thing_checker: bundle exec clock clocks/thing_checker.rb
thing_reporter: bundle exec clock clocks/thing_reporter.rb
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
the top of your Clockfile like this. You should handle these two cases so that you can get
error reports about problems while loading the Clockfile:

```ruby
on_error do |job, error|
  case job
  when String # this means there was a problem parsing the Clockfile while starting
    ErrorReporter.track_exception(error, tag: 'clock', severity: 'high')
  else
    ErrorReporter.track_exception(error, tag: 'clock', custom_attribute: {job_name: job.identifier})
  end
end
```

### Callbacks

You can define around callbacks which will run for all jobs, like shown below.
This somewhat awkward syntax is necessary in order to enable the ability to define multiple callbacks.
(perhaps in different files, shared by multiple Clockfiles, etc.).

```ruby
around_action do |job_proc, job_info|
  puts "before1 #{job_info.class}"
  job_proc.call
  puts "after1"
end

around_action do |job_proc|
  puts "before2"
  job_proc.call
  puts "after2"
end

every('2 seconds') do
  puts "hello from a ruby-clock job"
end
```


```
before1 Rufus::Scheduler::EveryJob
before2
hello from a ruby-clock job
after2
after1
```

The around callbacks code will be run in the individual job thread.

rufus-scheduler also provides before and after hooks. ruby-clock does not provide convenience methods for these
but you can easily use them via the `schedule` object. These will run in the outer scheduling thread and not in
the job thread, so they may have slightly different behavior in some cases. There is likely no reason to use them
instead of `around_action`.
Read [the rufus-scheduler documentation](https://github.com/jmettraux/rufus-scheduler/#callbacks)
to learn how to do this. Where the documentation references `s`, you should use `schedule`.

### Shell commands

You can run shell commands in your jobs.

```ruby
every '1 day' do
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
every '1 day' do
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
you may want to run your shell jobs in their own separate clock process.

```
bundle exec clock clocks/main_jobs.rb
bundle exec clock clocks/shell_jobs.rb
```


### Rake tasks

You can run tasks from within the persistent runtime of ruby-clock, without
needing to shell out and start another process.

```ruby
every '1 day' do
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
every '1 second', name: 'my job' do
  Foo.bar
end
# => my job

every '1 day' do
  daily_things = Foo.setup_daily
  daily_things.process
  # TODO: figure out best time of day
end
# => daily_things.process

# n.b. ruby-clock isn't yet smart enough to remove trailing comments
every '1 week' do
  weekly_things = Foo.setup_weekly
  weekly_things.process # does this work???!1~
end
# => weekly_things.process # does this work???!1~
```

This can be used for keeping track of job behavior in logs or a
stats tracker. For example:

```ruby
around_action(job_proc, job_info)
  trigger_time = Time.now
  job_proc.call
  duration = Time.now-trigger_time.to_t
  StatsTracker.value('Clock: Job Execution Time', duration.round(2))
  StatsTracker.value("Clock: Job #{job_info.identifier} Execution Time", duration.round(2))
  StatsTracker.increment('Clock: Job Executions')
end

every '10 seconds', name: 'thread stats' do
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

### Other rufus-scheduler Options

All [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler/) options are set to defaults.
There is a `schedule` variable available in your Clockfile, which is the singleton instance of `Rufus::Scheduler`.
ruby-clock methods such as `every` and `cron` are convenience methods which invoke `schedule.every`
and `schedule.cron`.
Anything you can do on this instance, you can do in your Clockfile.
See the rufus-scheduler documentation to see what you can do.

If you have ideas for rufus-scheduler features that can be brought in as
more abstract or default ruby-clock behavior, let me know!

## Syntax highlighting for Clockfile

To tell github and maybe other systems to syntax highlight Clockfile, put this in a .gitattributes file:

```gitattributes
Clockfile linguist-language=Ruby
```


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
