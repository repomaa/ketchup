module Ketchup
  class StartPomodoroRequest < Request
    getter! task : String

    def parse_params(params)
      missing_params = InvalidParamsError.new(id, "required params: task")
      raise missing_params unless params
      task = nil
      parser = JSON::PullParser.new(params)
      parser.read_object do |key|
        case(key)
        when "task" then task = parser.read_string
        else raise InvalidParamsError.new(id, "invalid param #{key}")
        end
      end
      raise missing_params unless task
      @task = task
    end
  end
end
