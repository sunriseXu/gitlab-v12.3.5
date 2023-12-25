# frozen_string_literal: true

module QA
  context 'Geo', :orchestrated, :geo do
    describe 'GitLab wiki HTTP push' do
      after do
        # Log out so subsequent tests can start unauthenticated
        Runtime::Browser.visit(:geo_secondary, QA::Page::Dashboard::Projects)
        Page::Main::Menu.perform do |menu|
          menu.sign_out if menu.has_personal_area?(wait: 0)
        end
      end

      context 'wiki commit' do
        it 'is replicated to the secondary node' do
          wiki_title = 'Geo Replication Wiki'
          wiki_content = 'This tests replication of wikis via HTTP'
          push_content = 'This is from the Geo wiki push!'
          project_name = "geo-wiki-project-#{SecureRandom.hex(8)}"

          # Create new wiki and push wiki commit
          Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
            Page::Main::Login.perform(&:sign_in_using_credentials)

            project = Resource::Project.fabricate! do |project|
              project.name = project_name
              project.description = 'Geo project for wiki repo test'
            end

            wiki = Resource::Wiki.fabricate! do |wiki|
              wiki.project = project
              wiki.title = wiki_title
              wiki.content = wiki_content
              wiki.message = 'First commit'
            end

            expect(page).to have_content(wiki_content)

            Resource::Repository::WikiPush.fabricate! do |push|
              push.wiki = wiki
              push.file_name = 'Home.md'
              push.file_content = push_content
              push.commit_message = 'Update Home.md'
            end

            Page::Project::Menu.perform(&:click_wiki)
            expect(page).to have_content(push_content)
          end

          # Validate that wiki is synced on secondary node
          Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
            Page::Main::Login.perform(&:sign_in_using_credentials)

            EE::Page::Main::Banner.perform do |banner|
              expect(banner).to have_secondary_read_only_banner
            end

            Page::Main::Menu.perform do |menu|
              menu.go_to_projects
            end

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project_name)
              dashboard.go_to_project(project_name)
            end

            Page::Project::Menu.perform(&:click_wiki)

            Page::Project::Wiki::Show.perform do |show|
              expect(page).to have_content(wiki_title)
              expect(page).to have_content(push_content)
            end
          end
        end
      end
    end
  end
end
