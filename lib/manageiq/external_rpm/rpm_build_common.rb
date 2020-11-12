module ManageIQ
  module ExternalRpm
    module RpmBuildCommon
      def rpms
        rpms = if ENV["RPM"]
          Array(ENV["RPM"])
        else
          ManageIQ::ExternalRpm::ROOT.glob("packages/*").collect { |i| i.basename.to_s }
        end
      end
    end
  end
end
