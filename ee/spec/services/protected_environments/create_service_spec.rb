# frozen_string_literal: true
require 'spec_helper'

describe ProtectedEnvironments::CreateService, '#execute' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }

  let(:params) do
    attributes_for(:protected_environment,
                   deploy_access_levels_attributes: [{ access_level: maintainer_access }])
  end

  subject { described_class.new(project, user, params).execute }

  context 'with valid params' do
    it { is_expected.to be_truthy }

    it 'creates a record on ProtectedEnvironment' do
      expect { subject }.to change(ProtectedEnvironment, :count).by(1)
    end

    it 'creates a record on ProtectedEnvironment record' do
      expect { subject }.to change(ProtectedEnvironment::DeployAccessLevel, :count).by(1)
    end
  end

  context 'with invalid params' do
    let(:maintainer_access) { 0 }

    it 'returns a non-persisted Protected Environment record' do
      expect(subject.persisted?).to be_falsy
    end
  end

  context 'deploy access level by group' do
    let(:params) do
      attributes_for(:protected_environment,
                     deploy_access_levels_attributes: [{ group_id: group.id }])
    end

    context 'invalid group' do
      it_behaves_like 'invalid protected environment group' do
        it 'does not create protected environment' do
          expect { subject }.not_to change(ProtectedEnvironment, :count)
        end
      end
    end

    context 'valid group' do
      it_behaves_like 'valid protected environment group' do
        it 'creates protected environment' do
          expect { subject }.to change(ProtectedEnvironment, :count).by(1)
        end
      end
    end
  end
end
