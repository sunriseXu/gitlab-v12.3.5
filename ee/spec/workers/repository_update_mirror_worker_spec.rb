require 'spec_helper'

describe RepositoryUpdateMirrorWorker do
  describe '#perform' do
    let(:jid) { '12345678' }
    let!(:project) { create(:project) }
    let!(:import_state) { create(:import_state, :mirror, :scheduled, project: project) }

    before do
      allow(subject).to receive(:jid).and_return(jid)
    end

    it 'sets status as finished when update mirror service executes successfully' do
      expect_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :success)

      expect { subject.perform(project.id) }.to change { import_state.reload.status }.to('finished')
    end

    it 'sets status as failed when update mirror service executes with errors' do
      allow_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :error, message: 'error')

      expect { subject.perform(project.id) }.to raise_error(RepositoryUpdateMirrorWorker::UpdateError, 'error')
      expect(project.reload.import_status).to eq('failed')
    end

    context 'with another worker already running' do
      it 'returns nil' do
        mirror = create(:project, :repository, :mirror, :import_started)

        expect(subject.perform(mirror.id)).to be nil
      end
    end

    it 'marks mirror as failed when an error occurs' do
      allow_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_raise(RuntimeError)

      expect { subject.perform(project.id) }.to raise_error(RepositoryUpdateMirrorWorker::UpdateError)
      expect(import_state.reload.status).to eq('failed')
    end

    context 'when worker was reset without cleanup' do
      let(:started_project) { create(:project) }
      let(:import_state) { create(:import_state, :mirror, :started, project: started_project, jid: jid) }

      it 'sets status as finished when update mirror service executes successfully' do
        expect_any_instance_of(Projects::UpdateMirrorService).to receive(:execute).and_return(status: :success)

        expect { subject.perform(started_project.id) }.to change { import_state.reload.status }.to('finished')
      end
    end
  end
end
