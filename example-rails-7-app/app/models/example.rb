class Example < ApplicationRecord
  def self.check_for_global_method
    if defined?(schedule)
      "💥 Oh no, the ruby-clock DSL is in the global environment! 💥"
    else
      "✅"
    end
  end

  def self.check_for_runner
    if defined?(shell) || defined?(rake)
      "💥 Oh no, the runners got included in the global environment! 💥"
    else
      "✅"
    end
  end

end
