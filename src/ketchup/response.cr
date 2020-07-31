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

    def to_json
      JSON.build do |json|
        json.object do
          json.field "jsonrpc", "2.0"
          json.field "id", @id
          json.field "result" { json.raw result.to_json } if success?
          json.field "error" { json.raw error.to_json } unless success?
        end
      end
    end
  end
end
