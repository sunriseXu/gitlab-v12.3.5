# frozen_string_literal: true

require 'spec_helper'

describe ContainerRegistry::Client do
  let(:token) { '12345' }
  let(:options) { { token: token } }
  let(:client) { described_class.new("http://registry", options) }

  describe '#push_blob' do
    let(:file) do
      file = Tempfile.new('test1')
      file.write('bla')
      file.close
      file
    end

    it 'PUT /v2/:name/blobs/uploads/url?digest=mytag' do
      stub_request(:put, "http://registry/v2/group/test/blobs/uploads/abcd?digest=mytag")
        .with(
          headers: {
            'Authorization' => 'bearer 12345',
            'Content-Length' => '3',
            'Content-Type' => 'application/octet-stream'
          })
        .to_return(status: 200, body: "", headers: {})

      stub_request(:post, "http://registry/v2/group/test/blobs/uploads/")
        .with(
          headers: {
            'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
            'Authorization' => 'bearer 12345'
          })
        .to_return(status: 200, body: "", headers: { 'Location' => 'http://registry/v2/group/test/blobs/uploads/abcd' })

      expect(client.push_blob('group/test', 'mytag', file.path)).to eq(true)
    end

    it 'raises error if response status is not 200' do
      stub_request(:put, "http://registry/v2/group/test/blobs/uploads/abcd?digest=mytag")
        .with(
          headers: {
            'Authorization' => 'bearer 12345',
            'Content-Length' => '3',
            'Content-Type' => 'application/octet-stream'
          })
        .to_return(status: 404, body: "", headers: {})

      stub_request(:post, "http://registry/v2/group/test/blobs/uploads/")
        .with(
          headers: {
            'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
            'Authorization' => 'bearer 12345'
          })
        .to_return(status: 200, body: "", headers: { 'Location' => 'http://registry/v2/group/test/blobs/uploads/abcd' })

      expect { client.push_blob('group/test', 'mytag', file.path) }
        .to raise_error(EE::ContainerRegistry::Client::Error)
    end
  end

  describe '#push_manifest' do
    let(:manifest) { 'manifest' }
    let(:manifest_type) { 'application/vnd.docker.distribution.manifest.v2+json' }

    it 'PUT v2/:name/manifests/:tag' do
      stub_request(:put, "http://registry/v2/group/test/manifests/my-tag")
        .with(
          body: "manifest",
          headers: {
            'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
            'Authorization' => 'bearer 12345',
            'Content-Type' => 'application/vnd.docker.distribution.manifest.v2+json'
          })
        .to_return(status: 200, body: "", headers: {})

      expect(client.push_manifest('group/test', 'my-tag', manifest, manifest_type)).to eq(true)
    end

    it 'raises error if response status is not 200' do
      stub_request(:put, "http://registry/v2/group/test/manifests/my-tag")
        .with(
          body: "manifest",
          headers: {
            'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
            'Authorization' => 'bearer 12345',
            'Content-Type' => 'application/vnd.docker.distribution.manifest.v2+json'
          })
        .to_return(status: 404, body: "", headers: {})

      expect { client.push_manifest('group/test', 'my-tag', manifest, manifest_type) }
        .to raise_error(EE::ContainerRegistry::Client::Error)
    end
  end

  describe '#blob_exists?' do
    let(:digest) { 'digest' }

    it 'returns true' do
      stub_request(:head, "http://registry/v2/group/test/blobs/digest")
        .with(
          headers: {
            'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
            'Authorization' => 'bearer 12345'
           })
        .to_return(status: 200, body: "", headers: {})

      expect(client.blob_exists?('group/test', digest)).to eq(true)
    end

    it 'returns false' do
      stub_request(:head, "http://registry/v2/group/test/blobs/digest")
        .with(
          headers: {
            'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
            'Authorization' => 'bearer 12345'
           })
        .to_return(status: 404, body: "", headers: {})

      expect(client.blob_exists?('group/test', digest)).to eq(false)
    end
  end

  describe '#repository_raw_manifest' do
    let(:manifest) { '{schemaVersion: 2, layers:[]}' }

    it 'GET "/v2/:name/manifests/:reference' do
      stub_request(:get, 'http://registry/v2/group/test/manifests/my-tag')
        .with(
          headers: {
            'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
            'Authorization' => 'bearer 12345'
          })
        .to_return(status: 200, body: manifest, headers: {})

      expect(client.repository_raw_manifest('group/test', 'my-tag')).to eq(manifest)
    end
  end
end
