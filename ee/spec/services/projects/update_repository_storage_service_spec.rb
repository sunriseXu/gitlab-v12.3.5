require 'spec_helper'

describe Projects::UpdateRepositoryStorageService do
  include Gitlab::ShellAdapter

  subject { described_class.new(project) }

  describe "#execute" do
    let(:time) { Time.now }

    before do
      allow(Time).to receive(:now).and_return(time)
    end

    context 'without wiki' do
      let(:project) { create(:project, :repository, repository_read_only: true, wiki_enabled: false) }

      context 'when the move succeeds' do
        it 'moves the repository to the new storage and unmarks the repository as read only' do
          old_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            project.repository.path_to_repo
          end

          expect_any_instance_of(Gitlab::Git::Repository).to receive(:fetch_repository_as_mirror)
            .with(project.repository.raw).and_return(true)

          subject.execute('test_second_storage')
          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('test_second_storage')
          expect(gitlab_shell.exists?('default', old_path)).to be(false)
          expect(project.project_repository.shard_name).to eq('test_second_storage')
        end
      end

      context 'when the project is already on the target storage' do
        it 'bails out and does nothing' do
          expect do
            subject.execute(project.repository_storage)
          end.to raise_error(described_class::RepositoryAlreadyMoved)
        end
      end

      context 'when the move fails' do
        it 'unmarks the repository as read-only without updating the repository storage' do
          expect_any_instance_of(Gitlab::Git::Repository).to receive(:fetch_repository_as_mirror)
            .with(project.repository.raw).and_return(false)
          expect(GitlabShellWorker).not_to receive(:perform_async)

          subject.execute('test_second_storage')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('default')
        end
      end
    end

    context 'with wiki' do
      let(:project) { create(:project, :repository, repository_read_only: true, wiki_enabled: true) }
      let(:repository_double) { double(:repository) }
      let(:wiki_repository_double) { double(:repository) }

      before do
        project.create_wiki

        # Default stub for non-specified params
        allow(Gitlab::Git::Repository).to receive(:new).and_call_original

        relative_path = project.repository.raw.relative_path
        allow(Gitlab::Git::Repository).to receive(:new)
          .with('test_second_storage', relative_path, "project-#{project.id}", project.full_path)
          .and_return(repository_double)

        wiki_relative_path = project.wiki.repository.raw.relative_path
        allow(Gitlab::Git::Repository).to receive(:new)
          .with('test_second_storage', wiki_relative_path, "wiki-#{project.id}", project.wiki.full_path)
          .and_return(wiki_repository_double)
      end

      context 'when the move succeeds' do
        it 'moves the repository and its wiki to the new storage and unmarks the repository as read only' do
          old_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            project.repository.path_to_repo
          end
          old_wiki_path = project.wiki.full_path

          expect(repository_double).to receive(:fetch_repository_as_mirror)
            .with(project.repository.raw).and_return(true)

          expect(wiki_repository_double).to receive(:fetch_repository_as_mirror)
            .with(project.wiki.repository.raw).and_return(true)

          subject.execute('test_second_storage')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('test_second_storage')
          expect(gitlab_shell.exists?('default', old_path)).to be(false)
          expect(gitlab_shell.exists?('default', old_wiki_path)).to be(false)
        end
      end

      context 'when the project is already on the target storage' do
        it 'bails out and does nothing' do
          expect do
            subject.execute(project.repository_storage)
          end.to raise_error(described_class::RepositoryAlreadyMoved)
        end
      end

      context 'when the move of the wiki fails' do
        it 'unmarks the repository as read-only without updating the repository storage' do
          expect(repository_double).to receive(:fetch_repository_as_mirror)
            .with(project.repository.raw).and_return(true)
          expect(wiki_repository_double).to receive(:fetch_repository_as_mirror)
            .with(project.wiki.repository.raw).and_return(false)
          expect(GitlabShellWorker).not_to receive(:perform_async)

          subject.execute('test_second_storage')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('default')
        end
      end
    end

    context 'when a object pool was joined' do
      let(:project) { create(:project, :repository, wiki_enabled: false, repository_read_only: true) }
      let(:pool) { create(:pool_repository, :ready, source_project: project) }

      it 'leaves the pool' do
        allow_any_instance_of(Gitlab::Git::Repository).to receive(:fetch_repository_as_mirror).and_return(true)

        subject.execute('test_second_storage')

        expect(project.reload_pool_repository).to be_nil
      end
    end
  end
end
