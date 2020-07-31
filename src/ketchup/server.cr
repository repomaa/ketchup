require "socket"

module Ketchup
  class Server
    def self.new(path : String)
      new(UNIXServer.new(path))
    end

    def self.new(host, port)
      new(TCPServer.new(host, port))
    end

    def initialize(@server)
      @state = State.new(STDOUT)
      @requests = Channel(Request).new
      @responses = {} of (Int64 | Float64 | String) => Channel(Response)
    end

    private def accept
      return @server.accept
    end

    private def handle_client(sock)
      STDOUT.puts "Client #{sock} connected"
      sock.sync = false
      until @wants_close
        begin
          message = sock.gets
          break unless message
          request = Request.from_json(message)
          id = request.id
          @responses[id] = Channel(Response).new(1) if id
          @requests.send(request)
          if id
            sock.puts(@responses[id].receive.to_json) 
            @responses.delete(id)
          end
        rescue e : Error
          sock.puts(ErrorResponse.new(e).to_json)
        end
        sock.flush
      end
    end

    private def handle_request(request)
      case request
      when PingRequest then SuccessResponse.new(request.id, "pong")
      when StartPomodoroRequest then start_pomodoro(request.id, request.task)
      when StartBreakRequest then start_break(request.id)
      when InterruptPomodoroRequest then interrupt_pomodoro(request.id, request.reason)
      when StatusRequest then status(request.id)
      else raise "unknown request"
      end
    end

    private def status(id)
      SuccessResponse.new(id, @state.status)
    end

    private def start_pomodoro(id, task)
      @state.start_pomodoro(task)
      SuccessResponse.new(id, "success")
    rescue
      ErrorResponse.new(id, 1000, "Pomodoro already running")
    end

    private def start_break(id)
      @state.start_break
      SuccessResponse.new(id, "success")
    rescue
      ErrorResponse.new(id, 1001, "Pomodoro still running")
    end

    private def interrupt_pomodoro(id, reason)
      @state.interrupt_pomodoro(reason)
      SuccessResponse.new(id, "success")
    rescue
      ErrorResponse.new(id, 1002, "Pomodoro is not running")
    end

    private def request_handler
      until @wants_close
        request = @requests.receive
        id = request.id
        @responses[id].send(handle_request(request)) if id
      end
    end

    def listen
      spawn request_handler
      until @wants_close
        spawn handle_client(accept)
      end
    end

    def close
      @wants_close = true
    end
  end
end
