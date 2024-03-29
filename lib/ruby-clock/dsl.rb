module RubyClock::DSL
  refine ::Kernel do
    def schedule
      RubyClock.instance.schedule
    end

    def on_error(&on_error_block)
      RubyClock.instance.on_error = on_error_block
      def schedule.on_error(job, error)
        RubyClock.instance.on_error.call(job, error)
      end
    end

    def around_action(&b)
      RubyClock.instance.around_actions << b
    end

    def cron(...)
      RubyClock.instance.schedule.cron(...)
    end

    def every(...)
      RubyClock.instance.schedule.every(...)
    end

    def shell(string)
      RubyClock.instance.shell(string)
    end

    def rake(string)
      RubyClock.instance.rake(string)
    end

    def rake_execute(string)
      RubyClock.instance.rake_execute(string)
    end

    def rake_async(string)
      RubyClock.instance.rake_async(string)
    end
  end
end
