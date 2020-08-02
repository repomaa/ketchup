require "./response"

module Ketchup
  class SuccessResponse < Response
    getter result

    def initialize(@id : Float64? | Int64? | Int32? | String?, @result : String | Hash(Symbol, Int32 | Int64 | String))
    end
  end
end
