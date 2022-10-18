require "ruby-clock/version"
require "ruby-clock/rake"
require 'rufus-scheduler'
require 'singleton'

class RubyClock
  include Singleton
  include RubyClock::Rake

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

  def shell_runner
    @shell_runner ||= begin
      require 'terrapin'
      require 'posix-spawn'

      unless Terrapin::CommandLine.runner.class == Terrapin::CommandLine::PosixRunner
        puts <<~MESSAGE

          🤷 terrapin and posix-spawn are installed, but for some reason terrapin is
             not using posix-spawn as its runner.

        MESSAGE
      end

      puts '🐆 Using terrapin for shell commands.'
      :terrapin
    rescue LoadError
      puts <<~MESSAGE

        🦥 Using ruby backticks for shell commands.
           For better performance, install the terrapin and posix-spawn gems.
           See README.md for more info.

      MESSAGE
      :backticks
    end
  end

  def shell(command)
    case shell_runner
    when :terrapin
      Terrapin::CommandLine.new(command).run
    when :backticks
      `#{command}`
    end
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
