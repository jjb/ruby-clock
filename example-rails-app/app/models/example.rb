class Example < ApplicationRecord
  def self.check_for_global_method
    if defined?(schedule)
      raise "Oh no, the ruby-clock DSL is in the global environment!"
    else
      "🦝"
    end
  end
end
