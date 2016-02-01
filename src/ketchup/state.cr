module Ketchup
  class State
    enum States
      Idle
      Pomodoro
      Break
      Interrupting
    end

    def initialize(@log)
      @current_task = nil
      @mutex = Channel(Bool).new(1)
      @mutex.send(true)
      @current_state = States::Idle
      @started_at = Time.epoch(0)
      @ending_at = Time.epoch(0)
      @pomodoro_index = 0
    end

    def start_pomodoro(task)
      synchronize { start_pomodoro_unsafe(task) }
    end

    def start_break
      synchronize { start_break_unsafe }
    end

    def interrupt_pomodoro(reason)
      synchronize { interrupt_pomodoro_unsafe(reason) }
    end

    def status
      synchronize { status_unsafe }
    end

    private def start_pomodoro_unsafe(task)
      raise "Already running" if pomodoro?

      current_task.try { |task| Hooks.task_stopped(task) }
      interrupt!
      Hooks.task_started(task)

      set_timer(task, States::Pomodoro, CONFIG.pomodoro_duration) { finish_pomodoro }
    end

    private def start_break_unsafe
      raise "Pomodoro is still running" if pomodoro?
      raise "Already on break" if break?

      current_task.try { |task| Hooks.task_stopped(task) }

      if pomodoro_index % CONFIG.cycle == 0
        duration = CONFIG.long_break_duration
        Hooks.long_break_started
      else
        duration = CONFIG.short_break_duration
        Hooks.short_break_started
      end

      set_timer(nil, States::Break, duration) { finish_break }
    end

    private def status_unsafe
      result = {} of Symbol => (String | Int32 | Int64)
      result[:state] = current_state.to_s.underscore
      unless current_state == States::Idle
        result[:ending_at] = ending_at.epoch
      end

      if current_state == States::Pomodoro
        current_task.try { |task| result[:current_task] = task }
      end

      result
    end

    private def interrupt_pomodoro_unsafe(reason)
      current_task.try do |task|
        Hooks.pomodoro_interrupted(task, reason || "unknown reason")
      end
      interrupt!
    end

    private def set_timer(task, state, duration, &on_finished)
      self.current_task = task
      self.current_state = state
      self.started_at = Time.now
      self.ending_at = started_at + duration

      spawn do
        until synchronize { interrupting? || Time.now >= ending_at }
          sleep 1
        end

        synchronize do
          on_finished.call unless interrupting?
          self.current_state = States::Idle
        end
      end
    end

    private def finish_pomodoro
      current_task.try { |task| Hooks.pomodoro_finished(task) }
      self.pomodoro_index = (pomodoro_index + 1) % 4
    end

    private def finish_break
      if ending_at - started_at == CONFIG.long_break_duration
        Hooks.long_break_finished
      else
        Hooks.short_break_finished
      end
    end

    private def synchronize
      @mutex.receive
      yield
    ensure
      @mutex.send(true)
    end

    private property current_state, current_task, pomodoro_index, started_at, ending_at

    {% for state in States.constants %}
      private def {{state.stringify.underscore.id}}?
        current_state == States::{{state}}
      end
    {% end %}

    private def interrupt!
      self.current_state = States::Interrupting
    end
  end
end
