#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'manageiq/external_rpm'
include ManageIQ::ExternalRpm::RpmBuildCommon
include ManageIQ::ExternalRpm::S3Common

if ENV["TRAVIS_JOB_NUMBER"].nil?
  puts "Skipping finalize, not running in Travis"
  exit 0
end

if ENV["TRAVIS_BRANCH"] != "master"
  puts "Skipping finalize, not running on master branch"
  exit 0
end

rpms.each do |rpm|
  puts "RPM: #{rpm}"
  build, _job = ENV["TRAVIS_JOB_NUMBER"].split(".")

  source_path = File.join("ci", build, rpm)
  list_objects(source_path) do |object|
    basename    = File.basename(object.key)
    destination = File.join("builds", rpm, basename)

    if list_objects(destination).to_a.length != 0
      puts "Skipping #{basename}, already exists"
      next
    end

    puts "Copying #{basename}"
    client.copy_object(
      :acl                => "public-read",
      :bucket             => ManageIQ::ExternalRpm::Settings.s3_api.bucket,
      :copy_source        => File.join(ManageIQ::ExternalRpm::Settings.s3_api.bucket, object.key),
      :key                => destination,
      :metadata_directive => "REPLACE",
    )
  end
end
