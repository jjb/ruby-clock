require "ruby-clock/version"
require 'rufus-scheduler'

module RubyClock
  def shutdown
    puts "Shutting down ruby-clock 🐈️ 👋"
    Rufus::Scheduler.singleton.shutdown(wait: 29)
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
