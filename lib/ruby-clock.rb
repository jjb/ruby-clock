require "ruby-clock/version"
require 'rufus-scheduler'

module RubyClock
  def shutdown
    wait_seconds = ENV['RUBY_CLOCK_SHUTDOWN_WAIT_SECONDS']&.to_i || 29
    puts "Shutting down ruby-clock. Waiting #{wait_seconds} seconds for jobs to finish..."
    Rufus::Scheduler.singleton.shutdown(wait: wait_seconds)
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
  end

  def schedule
    Rufus::Scheduler.singleton
  end

  def run_jobs
    puts "Starting ruby-clock with #{schedule.jobs.size} jobs"
    Rufus::Scheduler.singleton.join
  end
end
