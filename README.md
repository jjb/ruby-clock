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

ruby >= 3.0 is required.

Add this to your Gemfile:

```ruby
gem 'ruby-clock', require: false
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ruby-clock

## Usage

Create a file named Clockfile. This will hold your job definitions.
Define jobs like this:

```ruby
using RubyClock::DSL

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

You can also load multiple files with one invocation
(although a better approach might be to load your subfiles within a top-level Clockfile):

    bundle exec clock clocks/daily.rb clocks/weekly.rb

### Rails

To run your clock process in your app's environment:

    bundle exec clock

To get smarter database connection management (such as in the case of a database restart or upgrade,
and maybe other benefits) and code reloading in dev (app code, not the code in Clockfile itself),
jobs are automatically wrapped in the
[rails app reloader](https://guides.rubyonrails.org/threading_and_code_execution.html).

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

### Observing logs

Because STDOUT does not flush until a certain amount of data has gone into it,
you might not immediately see the ruby-clock startup message or job output if
viewing logs in a deployed environment such as Heroku where the logs are redirected
to another process or file. To change this behavior and have logs flush immediately,
add `$stdout.sync = true` to the top of your Clockfile.



### Testing

You can use the `--environment-and-syntax-check` flag to load the app environment and check
Clockfile syntax without actually running jobs. This can be used to check if cron syntax
is valid during dev, or in automate tests.

```ruby
# system returns true/false depending on 0/1 exit status of process
assert(system("bundle exec clock --environment-and-syntax-check clock/my_clockfile.rb"))
```

You can use `--check-slug-uniqueness` to check if all the auto-generated slugs are unique. If you have
multiple files with jobs, you need to pass them all in with one invocation in order to check global uniqueness.

```ruby
# system returns true/false depending on 0/1 exit status of process
assert(system("bundle exec clock --check-slug-uniqueness")) # loads Clockfile
assert(system("bundle exec clock --check-slug-uniqueness clock/weekly.rb clock/daily.rb")) # load specific files
```

### Visualization with cronv

Using the `--generate-dummy-crontab` flag you can visualize your schedule with [cronv](https://github.com/takumakanari/cronv).
For your jobs with cron-style schedules, it will generate a dummy crontab file that can be ingested by cronv.
For your jobs with "Every X seconds" schedules, a comment will be made in the file and they will not be vizualized.

```shell
## install go
brew install go # homebrew
sudo port install go # macports

## install cronv https://github.com/takumakanari/cronv#go-install
go install -v github.com/takumakanari/cronv/cronv@0.4.5

## generate dummy crontab
bundle exec clock --generate-dummy-crontab Clockfile ../clock/daily.rb ../clock/weekly.rb > dummycron.txt
## IMPORTANT: open dummycron.txt in an editor and remove the boot startup message cruft from the top
cat dummycron.txt | ~/go/bin/cronv --duration=1d --title='Clock Jobs' --width=50 -o ./my_cron_schedule.html
open my_cron_schedule.html
```

## Best Practice: use ruby-clock for scheduling, not work

It's a good idea to do as little work as possible in the clock job. Ideally, your clock jobs
will kick off background jobs. This allows the clock process to run with very little resources, even
for a Clockfile with hundreds of jobs that run close to one another or at the same time. It also decreases
the liklihood that a restart or deploy will cause a job to not run.

```ruby
# bad
every '1 minute' do
  User.needs_update.find_each{|u| u.update_stats }
end

# good
every '1 minute' do
  UserStatsUpdaterJob.perform_async
end
```

For this reason, there will probably never be support for using multiple cores. Even for a very complex schedule,
one core and not a lot of ram should suffice.

That said, it's perfectly fine to do work in ruby-clock. Maybe for a new project, you just have a few scheduled
tasks, and just want to write out the business logic all in one place and be done with it. There's no risk of lock-in
with this approach. You can easily move the work to a background job at any time down the road.

## More Config and Capabilities

### Error Handling

You can catch and report errors raised in your jobs by defining an error catcher at
the top of your Clockfile like this. You should handle these two cases so that you can get
error reports about problems while loading the Clockfile:

```ruby
on_error do |job, error|
  case job
  when String # this means there was a problem parsing the Clockfile while starting
    ErrorReporter.track_exception(StandardError.new(error), tag: 'clock', severity: 'high')
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

## Max Worker Threads

You can define the maximum number of worker threads that ruby-clock will use.

```ruby
schedule.max_work_threads = 42
```

[The default is 28](https://github.com/jmettraux/rufus-scheduler/#max_work_threads).

Impact of this number:
* **It will determine the max number of database connections
  used.** The highest number of simultaneous jobs running _which access the database_ will be the highest
  number of database connections used at any one time. If all of your jobs are not doing work, but only enqueueing background jobs,
  and you use a redis-backed background job system, then they will use no database connections, so even a high number of
  simultaneous threads is not an issue. If you use a database-backed background job system, that's a very different story, and
  you may want to keep this in mind when setting this value.
* **If threads are not available, jobs will wait to be enqueued.** If jobs are very fast (like if they only enqueue background jobs),
  then this doesn't matter much, even with a very high number of simultaneous jobs. If 100 jobs which each take an average of 1 second
  are scheduled at the same time:
  * with 100 threads they will take about 1 second
  * with 50 threads they will take about 2 seconds
  * with 25 threads they will take about 4 seconds
  * with 12 threads they will take about 8 seconds

### Variables

Like all rufus-scheduler features,
[local variables](https://github.com/jmettraux/rufus-scheduler/#--key-has_key-keys-values-and-entries)
can be defined per job. These can be used
in various ways, notably accessible by around actions and error handlers.

```ruby
cron '5 0 * * *', locals: { app_area: 'reports' } do
  DailyActivitySummary.generate_and_send
end

around_action do |job_proc, job_info|
  StatsTracker.increment("#{job_info[:app_area]} jobs")
  job_proc.call
end
on_error do |job, error|
  case job
  when String # this means there was a problem parsing the Clockfile while starting
    ErrorReporter.track_exception(error, tag: ['clock', job[:app_area]], severity: 'high')
  else
    ErrorReporter.track_exception(error, tag: ['clock', job[:app_area]], custom_attribute: {job_name: job.identifier})
  end
end
```

### Shell commands

You can run shell commands in your jobs.

```ruby
every '1 day' do
  shell('scripts/process_stuff.sh')
end
```

By default they will be run with
[ruby backticks](https://livebook.manning.com/concept/ruby/backtick).
For better performance, install the [terrapin](https://github.com/thoughtbot/terrapin)
gem.

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

There are also `rake_execute` and `rake_async`.
See [the code](https://github.com/jjb/ruby-clock/blob/main/lib/ruby-clock/rake.rb)
and [this article](https://code.jjb.cc/running-rake-tasks-from-within-ruby-on-rails-code) for more info.

### Job Identifier & Slug

ruby-clock adds the `identifier` method to `Rufus::Scheduler::Job`. This method will return the job's
[name](https://github.com/jmettraux/rufus-scheduler/#name--string) if one was given.
If a name is not given, the last non-comment code line in the job's block
will be used instead. If for some reason an error is encountered while calculating this, the next
fallback is the line number of the job in Clockfile.

There is also the `slug` method, which produces a slug using
[ActiveSupport parameterize](https://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-parameterize),
and with underscores changed to hyphens.
If the `activesupport` gem is not in your Gemfile and you attempt to use `slug`, it will fail.

Some examples of identifiers and slugs:

```ruby
every '1 second', name: 'my job' do
  Foo.bar
end
# my job, my-job

every '1 day' do
  daily_things = Foo.setup_daily
  daily_things.process
  # TODO: figure out best time of day
end
# daily_things.process, daily-things-process

# n.b. ruby-clock isn't yet smart enough to remove trailing comments
every '1 week' do
  weekly_things = Foo.setup_weekly
  weekly_things.process # does this work???!1~
end
# weekly_things.process # does this work???!1~, weekly-things-process-does-this-work-1
```

The identifier can be used for keeping track of job behavior in logs or a
stats tracker. For example:

```ruby
around_action do |job_proc, job_info|
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

The slug can be used for similar purposes where a slug-style string is needed. Here's an example
reporting a job to a scheduled job monitor, using
[healthchecks.io](https://blog.healthchecks.io/2023/07/new-feature-check-auto-provisioning/)
as an example:

```ruby
around_action do |job_proc, job_info|
  Net::HTTP.get("https://hc-ping.com/#{ENV['HEALTHCHECKS_PING_KEY']}/#{job_info.slug}/start?create=1")
  job_proc.call
  Net::HTTP.get("https://hc-ping.com/#{ENV['HEALTHCHECKS_PING_KEY']}/#{job_info.slug}?create=1")
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
