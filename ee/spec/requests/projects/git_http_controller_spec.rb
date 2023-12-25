# frozen_string_literal: true

require 'spec_helper'

describe Projects::GitHttpController, type: :request do
  include GitHttpHelpers

  describe 'GET #info_refs' do
    set(:user) { create(:user) }
    set(:project) { create(:project, :repository, :private) }
    let(:path) { "#{project.full_path}.git" }
    let(:env) { { user: user.username, password: user.password } }

    context 'smartcard session required' do
      subject { clone_get(path, env) }

      before do
        stub_licensed_features(smartcard_auth: true)
        stub_smartcard_setting(enabled: true, required_for_git_access: true)

        project.add_developer(user)
      end

      context 'user with a smartcard session', :clean_gitlab_redis_shared_state do
        let(:session_id) { '42' }
        let(:stored_session) do
          { 'smartcard_signins' => { 'last_signin_at' => 5.minutes.ago } }
        end

        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.set("session:gitlab:#{session_id}", Marshal.dump(stored_session))
            redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id])
          end
        end

        it "allows access" do
          subject

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'user without a smartcard session' do
        it "does not allow access" do
          subject

          expect(response).to have_gitlab_http_status(403)
          expect(response.body).to eq('Project requires smartcard login. Please login to GitLab using a smartcard.')
        end
      end

      context 'with the setting off' do
        before do
          stub_smartcard_setting(required_for_git_access: false)
        end

        it "allows access" do
          subject

          expect(response).to have_gitlab_http_status(200)
        end
      end
    end
  end
end
