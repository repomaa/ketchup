module Ketchup
  class Error < Exception
    getter id, code, message, data

    def initialize(@id, @code : Int, @message : String, @data = nil)
      super(@message)
    end

    def to_json(io)
      JSON.build io do |json|
        json.object do
          json.field "code", code
          json.field "message", message
          json.field "data" { data.to_json(io) } if data
        end
      end
    end
  end
end
