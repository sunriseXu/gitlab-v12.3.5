# frozen_string_literal: true

require 'spec_helper'

describe Groups::MergeRequestsController do
  let(:user)           { create(:user) }
  let(:group)          { create(:group, :public) }
  let(:project)        { create(:project, :repository, group: group) }
  let(:milestone)      { create(:milestone, group: group) }
  let(:merge_request1) { create(:merge_request, source_project: project, source_branch: 'branch-1') }
  let(:merge_request2) { create(:merge_request, source_project: project, source_branch: 'branch-2') }

  describe 'POST #bulk_update' do
    subject { post :bulk_update, params: params, format: :json }

    let(:params) do
      {
        update: {
          milestone_id: milestone.id,
          issuable_ids: "#{merge_request1.id}, #{merge_request2.id}"
        },
        group_id: group
      }
    end

    before do
      sign_in(user)
    end

    context 'when group bulk edit feature is not enabled' do
      before do
        stub_licensed_features(group_bulk_edit: false)
      end

      it 'returns 404 status' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when group bulk edit feature is enabled' do
      before do
        stub_licensed_features(group_bulk_edit: true)
      end

      context 'when user has permissions to bulk update merge requests' do
        before do
          group.add_developer(user)
        end

        it 'returns status 200' do
          subject

          expect(response.status).to eq(200)
        end

        it 'updates merge requests milestone' do
          expect { subject }
            .to change { merge_request1.reload.milestone }.from(nil).to(milestone)
            .and change { merge_request2.reload.milestone }.from(nil).to(milestone)
        end
      end

      context 'when user does not have permissions to bulk update merge requests' do
        before do
          group.add_reporter(user)
        end

        it 'returns status 404' do
          subject

          expect(response.status).to eq(404)
        end

        it 'does not update merge requests milestone' do
          expect { subject }
            .to not_change { merge_request1.reload.milestone }
            .and not_change { merge_request2.reload.milestone }
        end
      end
    end
  end
end
