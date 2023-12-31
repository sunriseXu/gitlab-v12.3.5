# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module MirroringRepositories
            def self.prepended(page)
              page.module_eval do
                view 'ee/app/views/projects/mirrors/_mirror_repos_form.html.haml' do
                  element :mirror_direction
                end

                view 'ee/app/views/projects/mirrors/_table_pull_row.html.haml' do
                  element :mirror_last_update_at_cell
                  element :mirror_repository_url_cell
                  element :mirrored_repository_row
                  element :update_now_button
                end
              end
            end
          end
        end
      end
    end
  end
end
