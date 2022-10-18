require "ruby-clock/version"
require "ruby-clock/rake"
require "ruby-clock/shell"
require 'rufus-scheduler'
require 'singleton'

class RubyClock
  include Singleton
  include RubyClock::Rake
  include RubyClock::Shell

  attr_accessor :on_error, :around_actions

  def initialize
    @around_actions = []

    def schedule.around_trigger(job_info, &job_proc)
      RubyClock.instance.call_with_around_action_stack(
        RubyClock.instance.around_actions.reverse,
        job_proc,
        job_info
      )
    end
  end

  def freeze_around_actions
    @around_actions.freeze
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

  def call_with_around_action_stack(wrappers, job_proc, job_info)
    case wrappers.count
    when 0
      job_proc.call(job_info)
    else
      call_with_around_action_stack(
        wrappers[1..],
        Proc.new{ wrappers.first.call(job_proc, job_info) },
        job_info
      )
    end
  end

end
