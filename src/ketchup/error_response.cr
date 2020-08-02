require "./response"

module Ketchup
  class ErrorResponse < Response
    getter error

    def initialize(@error)
      @id = @error.id
    end

    def initialize(@id : Float64? | Int64? | Int32? | String?, error_code, error_message, error_data = nil)
      @error = Error.new(@id, error_code, error_message, error_data)
    end
  end
end
