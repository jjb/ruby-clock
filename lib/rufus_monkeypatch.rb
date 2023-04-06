require 'method_source'
class Rufus::Scheduler::Job
  UNDESIRED_ELEMENTS = ['', '}', 'end']
  def identifier
    @identifier ||= begin
      return name if name

      lines = handler.source.split("\n")
      whitespace_removed = lines.map(&:strip)
      undesired_removed = whitespace_removed - UNDESIRED_ELEMENTS
      comment_only_lines_removed = undesired_removed.grep_v(/#.*/)
      comment_only_lines_removed[-1] # final line
    rescue
      begin
        source_location.join('-')
      rescue
        'error-calculating-job-identifier'
      end
    end
  end
end
