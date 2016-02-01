require "./core_ext/**"
require "./ketchup/config"

module Ketchup
  CONFIG_DIR = File.join(ENV["XDG_CONFIG_HOME"]? || File.join(ENV["HOME"], ".config"), "ketchup")
  CONFIG_FILE = File.join(CONFIG_DIR, "config.yml")
  CONFIG = File.exists?(CONFIG_FILE) ? Config.from_yaml(File.read(CONFIG_FILE)) : Config.new
end

require "./ketchup/*"

