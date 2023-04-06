require 'method_source'
class Rufus::Scheduler::Job
  def identifier
    @identifier ||= begin
      return name if name
      lines = handler.source.split("\n")
      blank_removed = lines.reject(&:empty?)
      comment_only_lines_removed = blank_removed.grep_v(/#.*/)
      final_line_that_is_not_end = comment_only_lines_removed[-2].strip
    rescue
      begin
        source_location.join('-')
      rescue
        'error-calculating-job-identifier'
      end
    end
  end
end
