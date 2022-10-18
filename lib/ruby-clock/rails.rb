# There is also rails-relevant code in rake.lib
module RubyClock::Rails
  module ClassMethods
    def detect_and_load_rails_app
      begin
        require './config/environment.rb'
        puts "Detected rails app has been loaded."
      rescue LoadError
      end
    end
  end

  module InstanceMethods
    def add_rails_executor_to_around_actions
      if defined?(::Rails)
        around_action do |job_proc|
          ::Rails.application.reloader.wrap do
            job_proc.call
          end
        end
      end
    end
  end
end
