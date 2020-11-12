#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'manageiq/external_rpm'
include ManageIQ::ExternalRpm::RpmBuildCommon
include ManageIQ::ExternalRpm::S3Common

def build_rpm(path)
  if path.glob("*.src.rpm").length > 0
    puts "Skipping SRPM build, SRPM exists"
    return
  end

  `docker run --rm -v #{path}:/root/working:z --cap-add=SYS_ADMIN bdunne/mock bash -c "cd /root/working && ls -al && rpmbuild -bs --define '_sourcedir /root/working' --define '_srcrpmdir /root/working' /root/working/#{File.basename(Dir.glob(path.join("*.spec")).first)}"`
end


rpms.each do |rpm|
  puts "RPM: #{rpm}"
  rpm_root = ManageIQ::ExternalRpm::ROOT.join("packages", rpm)

  download_directory(File.join("sources_cache", rpm), rpm_root)

  build_rpm(rpm_root)

  srpm = rpm_root.glob("*.src.rpm").first

  if ENV["TRAVIS_JOB_NUMBER"].nil?
    puts "Skipping upload, not running in Travis"
    next
  else
    build, _job = ENV["TRAVIS_JOB_NUMBER"].split(".")
    destination_filename = File.join("ci", build, rpm, srpm.basename)

    upload_file(srpm, destination_filename)
  end
end
