## 0.8.0 UNRELEASED

* fixed rare error when calculating job identifier
* nicer shutdown logging, indicating when shutdown process begins and ends
* ability to run rake tasks
* ability to run shell commands
* automatically wrap jobs with rails reloader

## 0.7.0

* ability to specify the name of the file with job definitions, e.g. `bundle exec clock clocks/MyClockfile`
* ability to specify the amount of time ruby-clock will wait before forcing threads to shut down

## 0.6.0

* job identifiers
