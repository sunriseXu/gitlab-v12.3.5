# frozen_string_literal: true

module QA
  module EE
    module Page
      module Component
        module WebIDE
          module WebTerminalPanel
            def self.prepended(page)
              page.module_eval do
                view 'app/assets/javascripts/ide/components/panes/right.vue' do
                  element :ide_right_sidebar
                  element :terminal_tab_button, %q(:data-qa-selector="`${tab.title.toLowerCase()}_tab_button`") # rubocop:disable QA/ElementWithPattern
                end

                view 'ee/app/assets/javascripts/ide/components/terminal/empty_state.vue' do
                  element :start_web_terminal_button
                end

                view 'ee/app/assets/javascripts/ide/components/terminal/terminal.vue' do
                  element :loading_container
                  element :terminal_screen
                end
              end
            end

            def has_finished_loading?
              wait(reload: false) do
                has_no_element? :loading_container
              end
            end

            def has_terminal_screen?
              wait(reload: false) do
                within_element :terminal_screen do
                  # The DOM initially just includes the :terminal_screen element
                  # and then the xterm package dynamically loads when the user
                  # clicks the Start Web Terminal button. If it loads succesfully
                  # an element with the class `xterm` is added to the DOM.
                  # The xterm is a third-party library, so we can't add a selector
                  find(".xterm")
                end
              end
            end

            def start_web_terminal
              within_element :ide_right_sidebar do
                click_element :terminal_tab_button
              end

              click_element :start_web_terminal_button

              has_element? :loading_container, text: "Starting"
            end
          end
        end
      end
    end
  end
end
