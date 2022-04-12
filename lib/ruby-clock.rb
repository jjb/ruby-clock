require "ruby-clock/version"
require 'rufus-scheduler'

puts @master_pid = Process.pid

module RubyClock
  def shutdown
    wait_seconds = ENV['RUBY_CLOCK_SHUTDOWN_WAIT_SECONDS']&.to_i || 29
    puts "Shutting down ruby-clock. Waiting #{wait_seconds} seconds for jobs to finish..."
    schedule.shutdown(wait: wait_seconds)
    puts "...done 🐈️ 👋"
  end

  def listen_to_signals
    signals = %w[INT TERM]
    signals.each do |signal|
      old_handler = Signal.trap(signal) do
        puts ">>> handling signal from #{Process.pid}"
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
    schedule.resume
    schedule.join
  end

  def prepare_rake
    if defined?(::Rails) && Rails.application
      Rails.application.load_tasks
      Rake::Task.tasks.each{|t| t.prerequisites.delete 'environment' }
      @rake_mutex = Mutex.new
    else
      puts <<~MESSAGE
        Because this is not a rails application, we do not know how to load your
        rake tasks. You can do this yourself at the top of your Clockfile if you want
        to run rake tasks from ruby-cron.
      MESSAGE
    end
  end

  # See https://code.jjb.cc/running-rake-tasks-from-within-ruby-on-rails-code

  # for tasks that don't have dependencies
  def rake_execute(task)
    Rake::Task[task].execute
  end

  # If the task doesn't share dependencies with another task,
  # or if it does and you know you'll never run tasks such that any overlap
  def rake_async(task)
    Rake::Task[task].invoke
  ensure
    Rake::Task[task].reenable
    Rake::Task[task].all_prerequisite_tasks.each(&:reenable)
  end

  # If the task has shared dependencies and you might run more than one at the same time
  # This is the safest option and hence the default.
  def rake(task)
    @rake_mutex.synchronize { rake_async(task) }
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

end
