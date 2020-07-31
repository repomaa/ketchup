require "yaml"

module Ketchup
  class BaseConfig
    include YAML::Serializable

    property pomodoro_duration : Int32 = 25
    property short_break_duration : Int32 = 5
    property long_break_duration : Int32 = 30
    property cycle : Int32 = 4
    property host : String = "localhost"
    property port : Int32 = 5678
    property socket : String?
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
