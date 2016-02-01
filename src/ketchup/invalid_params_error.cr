module Ketchup
  class InvalidParamsError < Error
    def initialize(id, data = nil)
      super(id, -32602, "Invalid params", data)
    end
  end
end
