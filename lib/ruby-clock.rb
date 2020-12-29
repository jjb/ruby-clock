require "ruby-clock/version"
require 'rufus-scheduler'

module RubyClock
  def shutdown
    puts "Shutting down 🐈️ 👋"
    puts Rufus::Scheduler.singleton.shutdown(wait: 29)
    exit
  end

  def listen_to_signals
    Signal.trap('INT') { shutdown }
    Signal.trap('TERM') { shutdown }
  end

  def schedule
    Rufus::Scheduler.singleton
  end

  def run_jobs
    Rufus::Scheduler.singleton.join
  end
end
