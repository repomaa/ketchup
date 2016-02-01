require "./response"

module Ketchup
  class SuccessResponse < Response
    getter result

    def initialize(@id, @result)
    end
  end
end
