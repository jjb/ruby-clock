This is a bare-bones example non-rails app to
help with dev and also as an example for users.

To run:

```
bundle
bundle exec clock
```

To test invocation of existing signal handlers, put this code at the very top of exe/clock:

```ruby
Signal.trap('INT') do
  puts "This is a well-behaving INT handler from outside of ruby-clock"
  exit
end
```
