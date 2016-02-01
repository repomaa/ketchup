module Ketchup
  class Error < Exception
    getter id, code, message, data

    def initialize(@id, @code : Int, @message : String, @data = nil)
      super(@message)
    end

    def to_json(io)
      io.json_object do |object|
        object.field "code", code
        object.field "message", message
        object.field "data" { data.to_json(io) } if data
      end
    end
  end
end
