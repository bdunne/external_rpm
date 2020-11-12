require 'pathname'

module ManageIQ
  module ExternalRpm
    ROOT       = Pathname.new("../..").expand_path(__dir__)
    CONFIG_DIR = ROOT.join("config")
  end
end

require 'manageiq/external_rpm/config'
require 'manageiq/external_rpm/rpm_build_common'
require 'manageiq/external_rpm/s3_common'
