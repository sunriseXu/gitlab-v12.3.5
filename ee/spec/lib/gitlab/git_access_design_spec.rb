# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::GitAccessDesign do
  include DesignManagementTestHelpers

  set(:project) { create(:project) }
  set(:user) { project.owner }
  let(:protocol) { 'web' }

  subject(:access) do
    described_class.new(user, project, protocol, authentication_abilities: [:read_project, :download_code, :push_code])
  end

  describe "#check!" do
    subject { access.check('git-receive-pack', ::Gitlab::GitAccess::ANY) }

    before do
      enable_design_management
    end

    context "when the user is allowed to manage designs" do
      it { is_expected.to be_a(::Gitlab::GitAccessResult::Success) }
    end

    context "when the user is not allowed to manage designs" do
      set(:user) { create(:user) }

      it "raises an error " do
        expect { subject }.to raise_error(::Gitlab::GitAccess::UnauthorizedError)
      end
    end

    context "when the protocol is not web" do
      let(:protocol) { 'https' }

      it "raises an error " do
        expect { subject }.to raise_error(::Gitlab::GitAccess::UnauthorizedError)
      end
    end
  end
end
