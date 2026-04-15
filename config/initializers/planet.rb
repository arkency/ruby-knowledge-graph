require "ostruct"

config_path = Rails.root.join("config", "planet.yml")
config_path = Rails.root.join("config", "planet.yml.example") unless config_path.exist?

planet_config = YAML.safe_load_file(config_path)
Rails.configuration.planet = OpenStruct.new(planet_config)
