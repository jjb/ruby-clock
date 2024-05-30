require "ruby-clock/version"
require "ruby-clock/rake"
require "ruby-clock/shell"
require "ruby-clock/around_actions"
require "ruby-clock/rails"
require 'rufus-scheduler'
require 'singleton'

class RubyClock
  include Singleton
  include RubyClock::Rails::InstanceMethods
  extend RubyClock::Rails::ClassMethods
  include RubyClock::Rake
  include RubyClock::Shell
  include RubyClock::AroundActions

  attr_accessor :on_error, :around_trigger_code_location

  def initialize
    set_up_around_actions
  end

  def wait_seconds
    ENV['RUBY_CLOCK_SHUTDOWN_WAIT_SECONDS']&.to_i || 29
  end

  # shutdown is done async in a Thread because signal handlers should
  # not have mutex locks created within them, which I believe can happen in
  # the rufus shutdown process
  def shutdown(old_handler=nil)
    Thread.new do
      sleep 0.1 # wait for trap block to exit
      puts "Shutting down ruby-clock. Waiting #{wait_seconds} seconds for jobs to finish..."
      schedule.shutdown(wait: wait_seconds)
      puts "...done 🐈️ 👋"
      if old_handler
        puts "handing off shutdown to another signal handler..."
        old_handler.call
      else
        exit
      end
    end
  end

  def listen_to_signals
    signals = %w[INT TERM]
    signals.each do |signal|
      old_handler = Signal.trap(signal) do
        if old_handler.respond_to?(:call)
          shutdown(old_handler)
        else
          shutdown
        end

        # keep this line here at the end, to serve as some degree of demonstration that
        # the handler exited before shutdown begins
        puts("received #{signal}") && STDOUT.flush
      end
    end
    puts "RUBY_CLOCK_SHUTDOWN_WAIT_SECONDS is set to #{wait_seconds}"
  end

  def schedule
    Rufus::Scheduler.singleton
  end

  def run_jobs
    puts "Starting ruby-clock with #{schedule.jobs.size} jobs"
    schedule.resume
    schedule.join
  end
end
