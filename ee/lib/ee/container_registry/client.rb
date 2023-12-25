# frozen_string_literal: true

module EE
  module ContainerRegistry
    module Client
      include ::Gitlab::Utils::StrongMemoize

      Error = Class.new(StandardError)

      # In the future we may want to read a small chunks into memory and use chunked upload
      # it will save us some IO.
      def push_blob(name, digest, file_path)
        payload = Faraday::UploadIO.new(file_path, 'application/octet-stream')
        url = get_upload_url(name, digest)
        headers = { 'Content-Type' => 'application/octet-stream', 'Content-Length' => payload.size.to_s }

        response = faraday.put(url, payload, headers)

        raise Error.new("Push Blob error: #{response.body}") unless response.success?

        true
      end

      def push_manifest(name, tag, manifest, manifest_type)
        response = faraday.put("v2/#{name}/manifests/#{tag}", manifest, { 'Content-Type' => manifest_type })

        raise Error.new("Push manifest error: #{response.body}") unless response.success?

        true
      end

      def blob_exists?(name, digest)
        faraday.head("/v2/#{name}/blobs/#{digest}").success?
      end

      # We currently use Faraday 0.12 which does not support streaming download yet
      # Given that we aim to migrate to HTTP.rb client and that updating Faraday is potentialy
      # dangerous, we use HTTP.rb here
      def pull_blob(name, digest)
        file = Tempfile.new("blob-#{digest}")

        response = HTTP
          .headers({ "Authorization" => "Bearer #{@options[:token]}" }) # rubocop:disable Gitlab/ModuleWithInstanceVariables
          .follow
          .get("#{@base_uri}/v2/#{name}/blobs/#{digest}") # rubocop:disable Gitlab/ModuleWithInstanceVariables
        response.body.each do |chunk|
          file.binmode
          file.write(chunk)
        end

        file
      ensure
        file.close
      end

      def repository_raw_manifest(name, reference)
        response_body faraday_raw.get("/v2/#{name}/manifests/#{reference}")
      end

      private

      def get_upload_url(name, digest)
        response = faraday.post("/v2/#{name}/blobs/uploads/")

        raise Error.new("Get upload URL error: #{response.body}") unless response.success?

        upload_url = URI(response.headers['location'])
        upload_url.query = "#{upload_url.query}&#{URI.encode_www_form(digest: digest)}"
        upload_url
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def faraday_raw
        strong_memoize(:faraday_raw) do
          Faraday.new(@base_uri) do |conn|
            initialize_connection(conn, @options, &method(:accept_raw_manifest))
          end
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def accept_raw_manifest(conn)
        conn.headers['Accept'] = ::ContainerRegistry::Client::ACCEPTED_TYPES
      end
    end
  end
end
