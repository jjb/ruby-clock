require "ruby-clock/version"
require "ruby-clock/rake"
require "ruby-clock/shell"
require "ruby-clock/around_actions"
require 'rufus-scheduler'
require 'singleton'

class RubyClock
  include Singleton
  include RubyClock::Rake
  include RubyClock::Shell
  include RubyClock::AroundActions

  attr_accessor :on_error

  def initialize
    set_up_around_actions
  end

  def wait_seconds
    ENV['RUBY_CLOCK_SHUTDOWN_WAIT_SECONDS']&.to_i || 29
  end

  def shutdown
    puts "Shutting down ruby-clock. Waiting #{wait_seconds} seconds for jobs to finish..."
    schedule.shutdown(wait: wait_seconds)
    puts "...done 🐈️ 👋"
  end

  def listen_to_signals
    signals = %w[INT TERM]
    signals.each do |signal|
      old_handler = Signal.trap(signal) do
        shutdown
        if old_handler.respond_to?(:call)
          old_handler.call
        else
          exit
        end
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
