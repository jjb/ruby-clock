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
