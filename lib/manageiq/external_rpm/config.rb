require 'config'

module ManageIQ
  module ExternalRpm
    Settings = Config.load_files(CONFIG_DIR.join("settings.yml"), CONFIG_DIR.join("settings.local.yml"))
  end
end
