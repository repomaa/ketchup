require "option_parser"
require "./ketchup"

module Ketchup
  module ClientCli
    enum Actions
      StartPomodoro
      InterruptPomodoro
      StartBreak
      Status
    end

    action = nil

    start_usage = "Usage: #{PROGRAM_NAME} [options] start task_name"
    interrupt_usage = "Usage: #{PROGRAM_NAME} [options] interrupt [reason]"
    break_usage = "Usage: #{PROGRAM_NAME} [options] break"
    status_usage = "Usage: #{PROGRAM_NAME} [options] status"

    base_parser = OptionParser.new do |parser|
      parser.banner = "Usage: #{PROGRAM_NAME} [options] [action [params...]]"

      parser.separator("\nOptions:")

      parser.on("-h HOST", "--host=HOST", "Host to connect to when using TCP (localhost by default)") do |host|
        CONFIG.host = host
      end

      parser.on("-p PORT", "--port=PORT", "TCP port to connect to (5678 by default)") do |port|
        CONFIG.port = port.to_i
      end

      parser.on("-s SOCKET", "--socket=SOCKET", "UNIX socket to connect to (overrides port)") do |socket|
        CONFIG.socket = socket
      end

      parser.on("-?", "--help", "Show this help. use <action> -h for more information on a specific action") do
        case(action)
        when Actions::StartPomodoro then puts start_usage
        when Actions::InterruptPomodoro then puts interrupt_usage
        when Actions::StartBreak then puts break_usage
        when Actions::Status then puts status_usage
        else puts parser
        end
        exit
      end

      parser.separator("\nActions (status is used if omitted):")

      parser.on("start", "Starts a pomodoro") do
        abort("Error: Multiple actions provided\n#{parser}") if action
        action = Actions::StartPomodoro
      end

      parser.on("interrupt", "Interrupts a pomodoro") do
        abort("Error: Multiple actions provided\n#{parser}") if action
        action = Actions::InterruptPomodoro
      end

      parser.on("break", "Starts a break") do
        abort("Error: Multiple actions provided\n#{parser}") if action
        action = Actions::StartBreak
      end

      parser.on("status", "Shows status of ketchup server") do
        abort("Error: Multiple actions provided\n#{parser}") if action
        action = Actions::Status
      end
    end

    begin
      base_parser.parse
      arg = ARGV.find { |arg| arg =~ /^[^\-]/ }
      raise "Unknown action '#{arg}'" if arg && !action
    rescue e
      abort("Error: #{e.message}\n#{base_parser}")
    end

    action ||= Actions::Status

    begin
      if socket = CONFIG.socket
        client = Client.new(socket)
      else
        client = Client.new(CONFIG.host, CONFIG.port)
      end
    rescue
      abort("Error: Failed to connect to server")
    end

    begin
      case(action)
      when Actions::StartPomodoro
        abort("Error: no task specified\n#{start_usage}") unless arg
        client.start_pomodoro(arg)
      when Actions::InterruptPomodoro then client.interrupt_pomodoro(arg)
      when Actions::StartBreak then client.start_break
      end
    rescue e
      abort("Error: #{e.message}")
    ensure
      puts client.status
    end
  end
end
