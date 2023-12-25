require 'spec_helper'

describe Gitlab::SidekiqConfig do
  describe '.workers' do
    it 'includes EE workers' do
      workers = described_class.workers

      expect(workers).to include(RepositoryUpdateMirrorWorker)
      expect(workers).to include(LdapGroupSyncWorker)
    end
  end

  describe '.worker_queues' do
    it 'includes EE queues' do
      queues = described_class.worker_queues

      expect(queues).to include('repository_update_mirror')
      expect(queues).to include('ldap_group_sync')
    end
  end

  describe '.expand_queues' do
    it 'expands queue namespaces to concrete queue names' do
      queues = described_class.expand_queues(%w[cronjob])

      expect(queues).to include('cronjob:stuck_import_jobs')
      expect(queues).to include('cronjob:stuck_merge_jobs')
    end

    it 'lets concrete queue names pass through' do
      queues = described_class.expand_queues(%w[post_receive])

      expect(queues).to include('post_receive')
    end

    it 'lets unknown queues pass through' do
      queues = described_class.expand_queues(%w[unknown])

      expect(queues).to include('unknown')
    end
  end
end
