## UNRELEASED

* fix detection of Rails constant, for non-rails apps

## 0.8.0 RC1

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
