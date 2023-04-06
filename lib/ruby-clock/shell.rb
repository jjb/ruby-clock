module RubyClock::Shell
  def shell_runner
    @shell_runner ||= begin
      require 'terrapin'
      unless Terrapin::CommandLine.runner.class == Terrapin::CommandLine::ProcessRunner
        puts <<~MESSAGE

          🤷 terrapin is installed, but for some reason terrapin is
            using backticks as its runner.

        MESSAGE
      end

      puts '🐆 Using terrapin for shell commands.'
      :terrapin
    rescue LoadError
      puts <<~MESSAGE

        🦥 Using ruby backticks for shell commands.
           For better performance, install the terrapin gem.
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
