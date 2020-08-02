require "./request"

module Ketchup
  class InterruptPomodoroRequest < Request
    getter reason : String?

    def parse_params(params)
      return unless params
      parser = JSON::PullParser.new(params)
      parser.read_object do |key|
        case key
        when "reason" then @reason = parser.read_string
        else raise InvalidParamsError.new(id, "invalid param #{key}")
        end
      end
    end
  end
end
