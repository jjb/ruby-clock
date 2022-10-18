require 'method_source'
class Rufus::Scheduler::Job
  def identifier
    @identifier ||= begin
      name || handler.source.split("\n").reject(&:empty?).grep_v(/#.*/)[-2].strip
    rescue
      begin
        source_location.join('-')
      rescue
        'error-calculating-job-identifier'
      end
    end
  end
end
