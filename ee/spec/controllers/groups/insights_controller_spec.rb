# frozen_string_literal: true

require 'spec_helper'

describe Groups::InsightsController do
  set(:parent_group) { create(:group, :private) }
  set(:nested_group) { create(:group, :private, parent: parent_group) }
  set(:project) { create(:project, :private) }
  set(:insight) { create(:insight, group: parent_group, project: project) }
  set(:user) { create(:user) }
  let(:query_params) { { chart_type: 'bar', query: { issuable_type: 'issue', collection_labels: ['bug'] } } }

  before do
    stub_licensed_features(insights: true)
    sign_in(user)
    parent_group.add_developer(user)
    nested_group.add_developer(user)
  end

  shared_examples '404 status' do
    it 'returns 404 status' do
      subject

      expect(response).to have_gitlab_http_status(404)
    end
  end

  shared_examples '200 status' do
    it 'returns 200 status' do
      subject

      expect(response).to have_gitlab_http_status(200)
    end
  end

  context 'when insights configuration project cannot be read by current user' do
    context 'when visiting the parent group' do
      describe 'GET #show.html' do
        subject { get :show, params: { group_id: parent_group.to_param } }

        it_behaves_like '404 status'
      end

      describe 'GET #show.json' do
        subject { get :show, params: { group_id: parent_group.to_param }, format: :json }

        it_behaves_like '404 status'
      end

      describe 'POST #query' do
        subject { post :query, params: query_params.merge(group_id: parent_group.to_param) }

        it_behaves_like '404 status'
      end
    end

    context 'when visiting a nested group' do
      describe 'GET #show.html' do
        subject { get :show, params: { group_id: nested_group.to_param } }

        # The following expectation should be changed to
        # it_behaves_like '404 status'
        # once https://gitlab.com/gitlab-org/gitlab/issues/11340 is implemented.
        it_behaves_like '200 status'
      end

      describe 'GET #show.json' do
        subject { get :show, params: { group_id: nested_group.to_param }, format: :json }

        # The following expectation should be changed to
        # it_behaves_like '404 status'
        # once https://gitlab.com/gitlab-org/gitlab/issues/11340 is implemented.
        it_behaves_like '200 status'

        # The following expectation should be removed
        # once https://gitlab.com/gitlab-org/gitlab/issues/11340 is implemented.
        it 'does return the default config' do
          subject

          expect(response.parsed_body).to eq(parent_group.default_insights_config.to_json)
        end
      end

      describe 'POST #query.json' do
        subject { post :query, params: query_params.merge(group_id: nested_group.to_param), format: :json }

        # The following expectation should be changed to
        # it_behaves_like '404 status'
        # once https://gitlab.com/gitlab-org/gitlab/issues/11340 is implemented.
        it_behaves_like '200 status'
      end
    end
  end

  context 'when insights configuration project can be read by current user' do
    before do
      project.add_reporter(user)
    end

    context 'when the configuration is attached to the current group' do
      describe 'GET #show.html' do
        subject { get :show, params: { group_id: parent_group.to_param } }

        it_behaves_like '200 status'
      end

      describe 'GET #show.sjon' do
        subject { get :show, params: { group_id: parent_group.to_param }, format: :json }

        it_behaves_like '200 status'
      end

      describe 'POST #query.json' do
        subject { post :query, params: query_params.merge(group_id: parent_group.to_param), format: :json }

        it_behaves_like '200 status'
      end
    end

    context 'when the configuration is attached to a nested group' do
      describe 'GET #show.html' do
        subject { get :show, params: { group_id: nested_group.to_param } }

        it_behaves_like '200 status'
      end

      describe 'GET #show.json' do
        subject { get :show, params: { group_id: nested_group.to_param }, format: :json }

        it_behaves_like '200 status'
      end

      describe 'POST #query.json' do
        subject { post :query, params: query_params.merge(group_id: nested_group.to_param), format: :json }

        it_behaves_like '200 status'
      end
    end
  end
end
