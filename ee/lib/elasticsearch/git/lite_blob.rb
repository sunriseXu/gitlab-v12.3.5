# frozen_string_literal: true

module Elasticsearch
  module Git
    class LiteBlob
      include ::Gitlab::BlobHelper
      include Elasticsearch::Git::EncoderHelper

      attr_accessor :id, :name, :path, :size, :mode, :commit_id
      attr_writer :data

      def initialize(repo, raw_blob_hash)
        @id   = raw_blob_hash[:oid]
        @blob = repo.lookup(@id)

        @mode = (raw_blob_hash[:mode] || raw_blob_hash[:filemode]).to_s(8)
        @size = @blob.size
        @path = encode!(raw_blob_hash[:path])
        @name = @path.split('/').last
      end

      def data
        @data ||= encode!(@blob.content)
      end
    end
  end
end
