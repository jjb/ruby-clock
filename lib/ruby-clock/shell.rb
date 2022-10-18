module RubyClock::Shell
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
