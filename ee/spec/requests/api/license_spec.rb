require 'spec_helper'

describe API::License, api: true do
  include ApiHelpers

  let(:gl_license)  { build(:gitlab_license) }
  let(:license)     { build(:license, data: gl_license.export) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  def license_json(license)
    {
      id: license.id,
      plan: license.plan,
      created_at: license.created_at.iso8601(3),
      starts_at: license.starts_at.to_date.to_s,
      expires_at: license.expires_at.to_date.to_s,
      historical_max: license.historical_max,
      licensee: license.licensee,
      add_ons: license.add_ons,
      expired: license.expired?,
      overage: license.overage,
      user_limit: license.restricted_user_count
    }
  end

  describe 'GET /license' do
    it 'retrieves the license information if admin is logged in' do
      get api('/license', admin)
      expect(response.status).to eq 200
      expect(json_response['user_limit']).to eq 0
      expect(Date.parse(json_response['starts_at'])).to eq Date.today - 1.month
      expect(Date.parse(json_response['expires_at'])).to eq Date.today + 11.months
      expect(json_response['active_users']).to eq 1
      expect(json_response['licensee']).not_to be_empty
      expect(json_response['add_ons']).to eq(license.add_ons)
    end

    it 'denies access if not admin' do
      get api('/license', user)
      expect(response.status).to eq 403
    end
  end

  describe 'POST /license' do
    it 'adds a new license if admin is logged in' do
      post api('/license', admin), params: { license: gl_license.export }

      expect(response.status).to eq 201
      expect(json_response['user_limit']).to eq 0
      expect(Date.parse(json_response['starts_at'])).to eq Date.today - 1.month
      expect(Date.parse(json_response['expires_at'])).to eq Date.today + 11.months
      expect(json_response['active_users']).to eq 1
      expect(json_response['licensee']).not_to be_empty
    end

    it 'denies access if not admin' do
      post api('/license', user), params: { license: license }

      expect(response.status).to eq 403
    end

    it 'returns 400 if the license cannot be saved' do
      post api('/license', admin), params: { license: 'foo' }

      expect(response.status).to eq(400)
    end
  end

  describe 'DELETE /license/:id' do
    let(:license) { create(:license, created_at: Time.now, data: build(:gitlab_license, starts_at: Date.today, expires_at: Date.today, restrictions: { add_ons: { 'GitLab_DeployBoard' => 1 }, active_user_count: 2 }).export) }
    let(:endpoint) { "/license/#{license.id}" }

    it 'destroys a license and returns 204' do
      delete api(endpoint, admin)

      expect(response.status).to eq(204)
      expect(response.message).to eq('No Content')
      expect(License.where(id: license.id)).not_to exist
    end

    it "returns an error if the license doesn't exist" do
      delete api("/license/0", admin)

      expect(response.status).to eq(404)
      expect(json_response['message']).to eq('404 Not found')
    end

    it 'returns 403 if the user is not an admin' do
      delete api(endpoint, user)

      expect(response.status).to eq(403)
      expect(json_response['message']).to eq('403 Forbidden')
    end
  end

  describe 'GET /licenses' do
    let(:endpoint) { '/licenses' }
    let(:gl_licenses) do
      [build(:gitlab_license, starts_at: Date.today - 10, expires_at: Date.today - 1, restrictions: { add_ons: { 'GitLab_FileLocks' => 1 }, active_user_count: 10 }),
       build(:gitlab_license, starts_at: Date.today - 20, expires_at: Date.today + 1, restrictions: { add_ons: { 'GitLab_DeployBoard' => 1 }, active_user_count: 20 })]
    end
    let!(:licenses) do
      [create(:license, created_at: Time.now + 30, data: gl_licenses[0].export),
       create(:license, created_at: Time.now + 20, data: gl_licenses[1].export)]
    end

    it 'returns a collection of licenses' do
      get api(endpoint, admin)

      expect(response.status).to eq(200)

      2.times do
        expect(json_response.shift.symbolize_keys).to contain_exactly(*license_json(licenses.pop))
      end
    end

    it 'returns an empty array if no licenses exist' do
      License.delete_all

      get api(endpoint, admin)

      expect(response.status).to eq(200)
      expect(json_response).to eq([])
    end

    it 'returns 403 if the user is not an admin' do
      get api(endpoint, user)

      expect(response.status).to eq(403)
      expect(json_response['message']).to eq('403 Forbidden')
    end
  end
end
