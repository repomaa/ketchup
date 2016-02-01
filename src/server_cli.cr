require "option_parser"
require "./ketchup"

module Ketchup
  module ServerCli
    OptionParser.parse! do |parser|
      parser.banner = "Usage: #{$0} [options]"

      parser.separator("\nOptions:")
      parser.on("-h HOST", "--host=HOST", "Host to listen on when using TCP (localhost by default)") do |host|
        CONFIG.host = host
      end

      parser.on("-p PORT", "--port=PORT", "Listen on given TCP port (5678 by default)") do |port|
        CONFIG.port = port.to_i
      end

      parser.on("-s SOCKET", "--socket=SOCKET", "Listen on given UNIX socket (overrides port)") do |socket|
        CONFIG.socket = socket
      end

      parser.on("--pomodoro-duration=DURATION", "Duration of a pomodoro in minutes") do |duration|
        CONFIG.pomodoro_duration = duration.to_i32
      end

      parser.on("--short-break-duration=DURATION", "Duration of a short break in minutes") do |duration|
        CONFIG.short_break_duration = duration.to_i32
      end

      parser.on("--long-break-duration=DURATION", "Duration of a long break in minutes") do |duration|
        CONFIG.long_break_duration = duration.to_i32
      end

      parser.on("-c COUNT", "--cycle COUNT", "A cycle consists of COUNT pomodoros. After a cycle comes a long break. (4 by default)") do |count|
        CONFIG.cycle = count.to_i32
      end

      parser.on("-?", "--help", "Show this help") do
        puts parser
        exit
      end
    end

    if socket = CONFIG.socket
      puts "Listening on unix://#{socket}"
      server = Server.new(socket)
    else
      puts "Listening on tcp://#{CONFIG.host}:#{CONFIG.port}"
      server = Server.new(CONFIG.host, CONFIG.port)
    end

    server.listen
  end
end
