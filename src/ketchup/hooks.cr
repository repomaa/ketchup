module Ketchup
  module Hooks
    extend self

    def task_started(task)
      STDOUT.puts "Started with task #{task}"
      run_user_hook("task_started", [task])
    end

    def task_stopped(task)
      STDOUT.puts "Stopped #{task}"
      run_user_hook("task_stopped", [task])
    end

    def pomodoro_finished(task)
      STDOUT.puts "Finished pomodoro on #{task}"
      run_user_hook("pomodoro_finished", [task])
    end

    def pomodoro_interrupted(task, reason)
      STDOUT.puts "Interrupted pomodoro on #{task}. Reason: #{reason}"
      run_user_hook("pomodoro_interrupted", [task, reason])
    end

    def long_break_started
      STDOUT.puts "Started long break"
      run_user_hook("break_started", ["long"])
    end

    def short_break_started
      STDOUT.puts "Short break started"
      run_user_hook("break_started", ["short"])
    end

    def long_break_finished
      STDOUT.puts "Finished long break"
      run_user_hook("break_finished", ["long"])
    end

    def short_break_finished
      STDOUT.puts "Finished short break"
      run_user_hook("break_finished", ["short"])
    end

    private def run_user_hook(name, args)
      user_hook = File.join(CONFIG_DIR, "hooks", name)
      return unless File.exists?(user_hook) && File.executable?(user_hook)
      unless system(user_hook, args)
        STDERR.puts "ERROR: user hook `#{name}` failed with exit code #{$?.exit_code}"
      end
    end
  end
end
