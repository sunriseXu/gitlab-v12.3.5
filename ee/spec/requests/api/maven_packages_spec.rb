# frozen_string_literal: true
require 'spec_helper'

describe API::MavenPackages do
  let(:group)   { create(:group) }
  let(:user)    { create(:user) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:personal_access_token) { create(:personal_access_token, user: user) }
  let(:jwt_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
  let(:headers) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => jwt_token } }
  let(:headers_with_token) { headers.merge('Private-Token' => personal_access_token.token) }
  let(:job) { create(:ci_build, user: user) }
  let(:version) { '1.0-SNAPSHOT' }

  before do
    project.add_developer(user)
    stub_licensed_features(packages: true)
  end

  describe 'GET /api/v4/packages/maven/*path/:file_name' do
    let(:package) { create(:maven_package, project: project, name: project.full_path) }
    let(:maven_metadatum) { package.maven_metadatum }
    let(:package_file_xml) { package.package_files.find_by(file_type: 'xml') }

    context 'a public project' do
      it 'returns the file' do
        download_file(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'returns sha1 of the file' do
        download_file(package_file_xml.file_name + '.sha1')

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('text/plain')
        expect(response.body).to eq(package_file_xml.file_sha1)
      end
    end

    context 'internal project' do
      before do
        project.team.truncate
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      it 'returns the file' do
        download_file_with_token(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'denies download when no private token' do
        download_file(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(403)
      end

      it 'allows download with job token' do
        download_file(package_file_xml.file_name, job_token: job.token)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'returns the file' do
        download_file_with_token(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'denies download when not enough permissions' do
        project.add_guest(user)

        download_file_with_token(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(403)
      end

      it 'denies download when no private token' do
        download_file(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(403)
      end

      it 'allows download with job token' do
        download_file(package_file_xml.file_name, job_token: job.token)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end
    end

    it 'rejects request if feature is not in the license' do
      stub_licensed_features(packages: false)

      download_file(package_file_xml.file_name)

      expect(response).to have_gitlab_http_status(403)
    end

    context 'project name is different from a package name' do
      let(:package) { create(:maven_package, project: project) }

      it 'rejects request' do
        download_file(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def download_file(file_name, params = {}, request_headers = headers)
      get api("/packages/maven/#{maven_metadatum.path}/#{file_name}"), params: params, headers: request_headers
    end

    def download_file_with_token(file_name, params = {}, request_headers = headers_with_token)
      download_file(file_name, params, request_headers)
    end
  end

  describe 'GET /api/v4/groups/:id/-/packages/maven/*path/:file_name' do
    let(:package) { create(:maven_package, project: project) }
    let(:maven_metadatum) { package.maven_metadatum }
    let(:package_file_xml) { package.package_files.find_by(file_type: 'xml') }

    before do
      project.team.truncate
      group.add_developer(user)
    end

    context 'a public project' do
      it 'returns the file' do
        download_file(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'returns sha1 of the file' do
        download_file(package_file_xml.file_name + '.sha1')

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('text/plain')
        expect(response.body).to eq(package_file_xml.file_sha1)
      end
    end

    context 'internal project' do
      before do
        group.group_member(user).destroy
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      it 'returns the file' do
        download_file_with_token(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'denies download when no private token' do
        download_file(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'allows download with job token' do
        download_file(package_file_xml.file_name, job_token: job.token)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'returns the file' do
        download_file_with_token(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'denies download when not enough permissions' do
        group.add_guest(user)

        download_file_with_token(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(403)
      end

      it 'denies download when no private token' do
        download_file(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'allows download with job token' do
        download_file(package_file_xml.file_name, job_token: job.token)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end
    end

    it 'rejects request if feature is not in the license' do
      stub_licensed_features(packages: false)

      download_file(package_file_xml.file_name)

      expect(response).to have_gitlab_http_status(403)
    end

    def download_file(file_name, params = {}, request_headers = headers)
      get api("/groups/#{group.id}/-/packages/maven/#{maven_metadatum.path}/#{file_name}"), params: params, headers: request_headers
    end

    def download_file_with_token(file_name, params = {}, request_headers = headers_with_token)
      download_file(file_name, params, request_headers)
    end
  end

  describe 'GET /api/v4/projects/:id/packages/maven/*path/:file_name' do
    let(:package) { create(:maven_package, project: project) }
    let(:maven_metadatum) { package.maven_metadatum }
    let(:package_file_xml) { package.package_files.find_by(file_type: 'xml') }

    context 'a public project' do
      it 'returns the file' do
        download_file(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'returns sha1 of the file' do
        download_file(package_file_xml.file_name + '.sha1')

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('text/plain')
        expect(response.body).to eq(package_file_xml.file_sha1)
      end
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'returns the file' do
        download_file_with_token(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'denies download when not enough permissions' do
        project.add_guest(user)

        download_file_with_token(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(403)
      end

      it 'denies download when no private token' do
        download_file(package_file_xml.file_name)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'allows download with job token' do
        download_file(package_file_xml.file_name, job_token: job.token)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end
    end

    it 'rejects request if feature is not in the license' do
      stub_licensed_features(packages: false)

      download_file(package_file_xml.file_name)

      expect(response).to have_gitlab_http_status(403)
    end

    def download_file(file_name, params = {}, request_headers = headers)
      get api("/projects/#{project.id}/packages/maven/" \
              "#{maven_metadatum.path}/#{file_name}"), params: params, headers: request_headers
    end

    def download_file_with_token(file_name, params = {}, request_headers = headers_with_token)
      download_file(file_name, params, request_headers)
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/maven/*path/:file_name/authorize' do
    it 'authorizes posting package with a valid token' do
      authorize_upload_with_token

      expect(response).to have_gitlab_http_status(200)
      expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      expect(json_response['TempPath']).not_to be_nil
    end

    it 'rejects request without a valid token' do
      headers_with_token['Private-Token'] = 'foo'

      authorize_upload_with_token

      expect(response).to have_gitlab_http_status(401)
    end

    it 'rejects request without a valid permission' do
      project.add_guest(user)

      authorize_upload_with_token

      expect(response).to have_gitlab_http_status(403)
    end

    it 'rejects requests that did not go through gitlab-workhorse' do
      headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      authorize_upload_with_token

      expect(response).to have_gitlab_http_status(500)
    end

    it 'authorizes upload with job token' do
      authorize_upload(job_token: job.token)

      expect(response).to have_gitlab_http_status(200)
    end

    def authorize_upload(params = {}, request_headers = headers)
      put api("/projects/#{project.id}/packages/maven/com/example/my-app/#{version}/maven-metadata.xml/authorize"), params: params, headers: request_headers
    end

    def authorize_upload_with_token(params = {}, request_headers = headers_with_token)
      authorize_upload(params, request_headers)
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/maven/*path/:file_name' do
    let(:file_upload) { fixture_file_upload('ee/spec/fixtures/maven/maven-metadata.xml') }

    before do
      # by configuring this path we allow to pass temp file from any path
      allow(Packages::PackageFileUploader).to receive(:workhorse_upload_path).and_return('/')
    end

    it 'rejects requests without a file from workhorse' do
      upload_file_with_token

      expect(response).to have_gitlab_http_status(400)
    end

    it 'rejects request without a token' do
      upload_file

      expect(response).to have_gitlab_http_status(401)
    end

    it 'rejects request if feature is not in the license' do
      stub_licensed_features(packages: false)

      upload_file_with_token

      expect(response).to have_gitlab_http_status(403)
    end

    context 'when params from workhorse are correct' do
      let(:package) { project.packages.reload.last }
      let(:package_file) { package.package_files.reload.last }
      let(:params) do
        {
          'file.path' => file_upload.path,
          'file.name' => file_upload.original_filename
        }
      end

      it 'creates package and stores package file' do
        expect { upload_file_with_token(params) }.to change { project.packages.count }.by(1)
          .and change { Packages::MavenMetadatum.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)

        expect(response).to have_gitlab_http_status(200)
        expect(package_file.file_name).to eq(file_upload.original_filename)
      end

      it 'allows upload with job token' do
        upload_file(params.merge(job_token: job.token))

        expect(response).to have_gitlab_http_status(200)
      end

      context 'version is not correct' do
        let(:version) { '$%123' }

        it 'rejects request' do
          expect { upload_file_with_token(params) }.not_to change { project.packages.count }

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']).to include('Validation failed')
        end
      end
    end

    def upload_file(params = {}, request_headers = headers)
      put api("/projects/#{project.id}/packages/maven/com/example/my-app/#{version}/maven-metadata.xml"), params: params, headers: request_headers
    end

    def upload_file_with_token(params = {}, request_headers = headers_with_token)
      upload_file(params, request_headers)
    end
  end
end
