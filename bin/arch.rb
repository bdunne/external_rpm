#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'manageiq/external_rpm'
include ManageIQ::ExternalRpm::RpmBuildCommon
include ManageIQ::ExternalRpm::S3Common

def build_arch_rpm(path)
  srpm = "/root/working/#{File.basename(Dir.glob(path.join("*.src.rpm")).first)}"
  `docker run --rm -v #{path}:/root/working:z --cap-add=SYS_ADMIN bdunne/mock bash -c "cd /root/working && ls -al && yum-builddep -y #{srpm} && yum -y install which && rpmbuild --rebuild --define '_srcrpmdir /root/working' --define '_rpmdir /root/working' #{srpm}"`
end


rpms.each do |rpm|
  puts "RPM: #{rpm}"
  rpm_root = ManageIQ::ExternalRpm::ROOT.join("packages", rpm)

  if ENV["TRAVIS_JOB_NUMBER"]
    build, _job = ENV["TRAVIS_JOB_NUMBER"].split(".")
    download_directory(File.join("ci", build, rpm), rpm_root)
  end

  build_arch_rpm(rpm_root)

  if ENV["TRAVIS_JOB_NUMBER"].nil?
    puts "Skipping upload, not running in Travis"
    next
  else
    rpm_root.glob("**/*.rpm").each do |file|
      next if file.to_s.include?(".src.rpm")
      destination_filename = File.join("ci", build, rpm, file.basename)

      puts "Uploading #{file.basename}"
      upload_file(file, destination_filename)
    end
  end
end
