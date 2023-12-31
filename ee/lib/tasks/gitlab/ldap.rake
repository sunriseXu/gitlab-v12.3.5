namespace :gitlab do
  namespace :ldap do
    desc 'GitLab | LDAP | Run a GroupSync'
    task group_sync: :gitlab_environment do
      unless Gitlab::Auth::LDAP::Config.group_sync_enabled?
        $stdout.puts 'LDAP GroupSync is not enabled.'
        exit 1
      end

      $stdout.puts 'LDAP GroupSync is enabled.'
      $stdout.puts 'Starting GroupSync...'

      EE::Gitlab::Auth::LDAP::Sync::Groups.execute
      $stdout.puts 'Finished GroupSync.'
    end
  end
end
