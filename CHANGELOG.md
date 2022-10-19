## 2.0.0 beta

* The way the [rails app reloader](https://guides.rubyonrails.org/threading_and_code_execution.html)
  is implemented is now compatible with both rails 6 and 7
* The setup for rails is now less complicated
* RUBY_CLOCK_SHUTDOWN_WAIT_SECONDS value is logged when starting
* Code reorganization so there are no unnecessary methods in top-level Kernel namespace
* DSL methods are now at the top-level namespace (`schedule.every` → `every`, `schedule.cron` → `cron`)
* Error handler definition is now at the top-level namespace (`def schedule.on_error` → `on_error do`)
* Around callbacks now have a top-level namespace method, which is different from the above in that...
* Multiple around callbacks can be consecutively assigned
* Report errors to error reporter when loading Clockfile

### Migrating from ruby-clock version 1 to version 2

* if you have and existing `def schedule.around_trigger`, you will need to change it to use the new
  `around_action` method. see readme.
* There is no longer a need to have a binstub in rails. You can delete bin/clock from your app.
* The invocations (in Procfile, or wherever else you start ruby-clock) should change from

      bundle exec rails runner bin/clock
  to

      bundle exec clock
* Your existing Clockfile will still work, but you now have the option to use
  `every`, `cron`, and `on_error` at the top-level, without referencing `schedule`.
  See the readme for examples.

## 1.0.0

* make terrapin and posix-spawn gems optional
* fix detection of Rails constant, for non-rails apps
* automatically wrap jobs with rails reloader
* ability to run rake tasks
* ability to run shell commands
* nicer shutdown logging, indicating when shutdown process begins and ends
* fix approach for error fallbacks when when calculating job identifier (probably never encountered)

## 0.7.0

* ability to specify the name of the file with job definitions, e.g. `bundle exec clock clocks/MyClockfile`
* ability to specify the amount of time ruby-clock will wait before forcing threads to shut down

## 0.6.0

* job identifiers
