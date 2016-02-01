require "json"

module Ketchup
  abstract class Response
    getter id

    def initialize(@id)
    end

    def result
    end

    def success?
      error.nil?
    end

    def error : Error?
    end

    def to_json(io)
      io.json_object do |object|
        object.field "jsonrpc", "2.0"
        object.field "id", @id
        object.field "result" { result.to_json(io) } if success?
        object.field "error" { error.to_json(io) } unless success?
      end
    end
  end
end
