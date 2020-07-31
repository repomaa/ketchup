module Ketchup
  class Client
    def self.new(host, port)
      new(TCPSocket.new(host, port))
    end

    def self.new(socket : String)
      new(UNIXSocket.new(socket))
    end

    def initialize(@connection : Socket)
      @id = 0
    end

    def status
      result = rpc("status")
      task = nil
      state = nil
      ending_at = nil

      parser = JSON::PullParser.new(result)
      parser.read_object do |key|
        case key
        when "current_task" then task = parser.read_string
        when "state" then state = parser.read_string
        when "ending_at" then ending_at = Time.unix(parser.read_int)
        end
      end

      String.build do |builder|
        builder << "[#{state}]"
        builder << %( "#{task}") if task
        if ending_at
          time_left = ending_at - Time.utc
          time_left = Time::Span.new(hours: time_left.hours, minutes: time_left.minutes, seconds: time_left.seconds)
          builder << " ends in #{time_left}"
        end
      end
    end

    def start_pomodoro(task)
      rpc("start_pomodoro", { task: task })
    end

    def interrupt_pomodoro(reason = nil)
      rpc("interrupt_pomodoro", reason ? { reason: reason } : nil)
    end

    def start_break
      rpc("start_break")
    end

    private def rpc(method, params = nil)
      JSON.build @connection do |json|
        json.object do
          json.field "jsonrpc", "2.0"
          json.field "id", @id
          json.field "method", method
          json.field "params", params if params
        end
      end

      @connection.puts
      @connection.flush
      @id += 1
      response = @connection.gets
      raise "No response from server" unless response
      result_io = String::Builder.new

      parser = JSON::PullParser.new(response)
      parser.read_object do |key|
        case key
        when "error" then raise parse_error(parser)
        when "result" then result_io = JSON.build { |json| parser.read_raw(json) }
        else parser.skip
        end
      end

      result_io.to_s
    end

    private def parse_error(parser)
      message = nil
      data = nil

      parser.read_object do |key|
        case key
        when "message" then message = parser.read_string
        when "data" then data = parser.read_string
        else parser.skip
        end
      end

      "#{message} - #{data}"
    end
  end
end
