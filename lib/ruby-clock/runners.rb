# if we ever want to make these available at the top-level using refinements,
# like we do with the DSL, it doesn't work in Rails because Rails prepends Kernel after
# we use the refinment. Initial tests show that prepending ActiveSupport::ForkTracker::CoreExtPrivate
# works, but maybe that's not reliable or has unknown side effects
# https://stackoverflow.com/questions/74119178/

module RubyClock::Runners
  def self.shell(string)
    RubyClock.instance.shell(string)
  end

  def self.rake(string)
    RubyClock.instance.rake(string)
  end

  def self.rake_execute(string)
    RubyClock.instance.rake_execute(string)
  end

  def self.rake_async(string)
    RubyClock.instance.rake_async(string)
  end
end
