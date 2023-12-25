# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project::Secure
        class Show < QA::Page::Base
          view 'ee/app/assets/javascripts/security_dashboard/components/vulnerability_count.vue' do
            element :vulnerability_count, ':data-qa-selector="qaSelector"' # rubocop:disable QA/ElementWithPattern
          end

          view 'ee/app/assets/javascripts/security_dashboard/components/filter.vue' do
            element :filter_dropdown, ':data-qa-selector="qaSelector"' # rubocop:disable QA/ElementWithPattern
            element :filter_dropdown_content
          end

          def filter_report_type(report)
            click_element(:filter_report_type_dropdown)
            within_element(:filter_dropdown_content) do
              click_on report
            end
            # Click the dropdown to close the modal and ensure it isn't open if this function is called again
            click_element(:filter_report_type_dropdown)
          end

          def has_low_vulnerability_count_of?(expected)
            find_element(:vulnerability_count_low).has_content?(expected)
          end
        end
      end
    end
  end
end
