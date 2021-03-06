module ManageIQ
  module ExternalRpm
    module S3Common
      def client
        @client ||= begin
          require 'aws-sdk-s3'
          Aws::S3::Client.new(
            :access_key_id     => Settings.s3_api.access_key,
            :secret_access_key => Settings.s3_api.secret_key,
            :region            => 'us-east-1',
            :endpoint          => Settings.s3_api.endpoint
          )
        end
      end

      def remote_etag(key)
        client.head_object(
          :bucket => Settings.s3_api.bucket,
          :key    => key
        )[:etag].tr("\\\"", "")
      rescue Aws::S3::Errors::NotFound
      end

      def upload_file(source, destination)
        require 'digest'
        md5sum = Digest::MD5.file(source).hexdigest

        if md5sum == remote_etag(destination)
          puts "Skipping existing file: #{destination}"
          return false
        end

        delete_at = (Time.now.utc.to_i + 604800).to_s # One week from now

        puts "Uploading: #{destination}"
        File.open(source, 'rb') do |content|
          client.put_object(
            :bucket => Settings.s3_api.bucket,
            :key    => destination,
            :body   => content,
            :acl    => 'public-read',
            :metadata => {"delete_at" => delete_at}
          )
        end
        return true
      end

      def download_directory(source, destination_dir)
        list_objects(source) do |object|
          basename = File.basename(object.key)
          local_path = destination_dir.join(basename)
          if local_path.file?
            puts "Skipping existing file: #{basename}"
          else
            puts "Fetching source file: #{basename}"
            client.get_object(:bucket => ManageIQ::ExternalRpm::Settings.s3_api.bucket, :key => object.key, :response_target => local_path)
          end
        end
      end

      def list_objects(prefix, &block)
        return enum_for(__method__, prefix) unless block_given?

        client.list_objects(:bucket => ManageIQ::ExternalRpm::Settings.s3_api.bucket, :prefix => prefix).flat_map(&:contents).each do |object|
          next if object.key.end_with?("/") # The directory itself is in the list
          yield object
        end
      end
    end
  end
end
