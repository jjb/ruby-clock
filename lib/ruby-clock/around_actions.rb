module RubyClock::AroundActions

  attr_accessor :around_actions

  def freeze_around_actions
    @around_actions.freeze
  end

  def set_up_around_actions
    @around_actions = []
    def schedule.around_trigger(job_info, &job_proc)
      RubyClock.instance.call_with_around_action_stack(
        RubyClock.instance.around_actions.reverse,
        job_proc,
        job_info
      )
    end
  end

  def call_with_around_action_stack(wrappers, job_proc, job_info)
    case wrappers.count
    when 0
      job_proc.call(job_info)
    else
      call_with_around_action_stack(
        wrappers[1..],
        Proc.new{ wrappers.first.call(job_proc, job_info) },
        job_info
      )
    end
  end
end
