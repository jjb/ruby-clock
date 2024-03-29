# See https://code.jjb.cc/running-rake-tasks-from-within-ruby-on-rails-code
module RubyClock::Rake
  def prepare_rake
    if defined?(::Rails) && Rails.application
      Rails.application.load_tasks
      Rake::Task.tasks.each{|t| t.prerequisites.delete 'environment' }
      @rake_mutex = Mutex.new
    else
      puts <<~MESSAGE
        Because this is not a rails application, we do not know how to load your
        rake tasks. You can do this yourself at the top of your Clockfile if you want
        to run rake tasks from ruby-clock.
      MESSAGE
    end
  end

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

end
