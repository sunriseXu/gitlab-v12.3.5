# frozen_string_literal: true

module QA
  module EE
    module Resource
      module Board
        module BoardList
          module Project
            class LabelBoardList < BaseBoardList
              attribute :label do
                QA::Resource::Label.fabricate_via_api! do |label|
                  label.project = board.project
                  label.title = 'Doing'
                end
              end

              def api_post_body
                {
                  board_id: board.id,
                  label_id: label.id
                }
              end
            end
          end
        end
      end
    end
  end
end
