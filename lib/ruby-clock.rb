require "ruby-clock/version"
require 'rufus-scheduler'

module RubyClock
  def shutdown
    puts "Shutting down 🐈️ 👋"
    puts Rufus::Scheduler.singleton.shutdown(wait: 29)
  end

  def listen_to_signals
    signals = %w[INT TERM]
    signals.each do |signal|
      Signal.trap(signal) do
        shutdown
        exit
      end
    end
  end

  def schedule
    Rufus::Scheduler.singleton
  end

  def run_jobs
    Rufus::Scheduler.singleton.join
  end
end
