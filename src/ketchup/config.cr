require "yaml"

module Ketchup
  class BaseConfig
    YAML.mapping({
      pomodoro_duration: {
        type: Int32,
        default: 25
      },
      short_break_duration: {
        type: Int32,
        default: 5
      },
      long_break_duration: {
        type: Int32,
        default: 30
      },
      cycle: {
        type: Int32,
        default: 4
      },
      host: {
        type: String,
        default: "localhost"
      },
      port: {
        type: Int32,
        default: 5678
      },
      socket: {
        type: String,
        nilable: true
      }
    })
  end

  class Config < BaseConfig
    def self.new
      from_yaml("---\nfoo: bar")
    end

    def pomodoro_duration
      super.minutes
    end

    def short_break_duration
      super.minutes
    end

    def long_break_duration
      super.minutes
    end
  end
end
