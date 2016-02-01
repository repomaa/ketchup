require "json"

module JSON
  class PullParser
    def skip(io : IO)
      skip_internal(io)
    end

    private def skip_internal(io)
      case @kind
      when :null then read_null.to_json(io)
      when :bool then read_bool.to_json(io)
      when :int then read_int.to_json(io)
      when :float then read_float.to_json(io)
      when :string then read_string.to_json(io)
      when :begin_array
        io.json_array do |array|
          read_array do
            array.push { skip_internal(io) }
          end
        end
      when :begin_object
        io.json_object do |object|
          read_object do |key|
            object.field(key) { skip_internal(io) }
          end
        end
      else
        unexpected_token
      end
    end
  end
end
