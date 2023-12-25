# frozen_string_literal: true

module QA
  module EE
    module Page
      module MergeRequest
        module Show
          def self.prepended(page)
            page.module_eval do
              view 'app/assets/javascripts/vue_merge_request_widget/components/states/sha_mismatch.vue' do
                element :head_mismatch, "The source branch HEAD has recently changed." # rubocop:disable QA/ElementWithPattern
              end

              view 'ee/app/assets/javascripts/batch_comments/components/publish_button.vue' do
                element :submit_review
              end

              view 'ee/app/assets/javascripts/batch_comments/components/review_bar.vue' do
                element :review_bar
                element :discard_review
                element :modal_delete_pending_comments
              end

              view 'app/assets/javascripts/notes/components/note_form.vue' do
                element :unresolve_review_discussion_checkbox
                element :resolve_review_discussion_checkbox
                element :start_review
                element :comment_now
              end

              view 'ee/app/assets/javascripts/batch_comments/components/preview_dropdown.vue' do
                element :review_preview_toggle
              end

              view 'ee/app/views/projects/merge_requests/_code_owner_approval_rules.html.haml' do
                element :approver
                element :approver_list
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/grouped_security_reports_app.vue' do
                element :vulnerability_report_grouped
              end

              view 'app/assets/javascripts/reports/components/report_section.vue' do
                element :expand_report_button
              end

              view 'ee/app/assets/javascripts/vue_merge_request_widget/components/approvals/approvals.vue' do
                element :approve_button
              end

              view 'ee/app/assets/javascripts/vue_merge_request_widget/components/approvals/approvals_summary.vue' do
                element :approvals_summary_content
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/modal_footer.vue' do
                element :resolve_split_button
              end
            end
          end

          def approvals_required_from
            approvals_content.match(/approvals? from (.*)/)[1]
          end

          def approved?
            approvals_content =~ /Merge request approved/
          end

          def approvers
            within_element :approver_list do
              all_elements(:approver).map { |item| item.find('img')['title'] }
            end
          end

          def click_approve
            click_element :approve_button
          end

          def start_review
            click_element :start_review
          end

          def comment_now
            click_element :comment_now
          end

          def submit_pending_reviews
            within_element :review_bar do
              click_element :review_preview_toggle
              click_element :submit_review
            end
          end

          def discard_pending_reviews
            within_element :review_bar do
              click_element :discard_review
            end
            click_element :modal_delete_pending_comments
          end

          def resolve_review_discussion
            scroll_to_element :start_review
            check_element :resolve_review_discussion_checkbox
          end

          def unresolve_review_discussion
            check_element :unresolve_review_discussion_checkbox
          end

          def expand_vulnerability_report
            click_element :expand_report_button
          end

          def click_vulnerability(name)
            within_element :vulnerability_report_grouped do
              click_on name
            end
          end

          def resolve_vulnerability_with_mr(name)
            expand_vulnerability_report
            click_vulnerability(name)
            click_element :resolve_split_button
          end

          def has_vulnerability_report?(timeout: 60)
            wait(reload: true, max: timeout, interval: 1) do
              finished_loading?
              has_element?(:vulnerability_report_grouped, wait: 1)
            end
          end

          def has_detected_vulnerability_count_of?(expected)
            # Match text cut off in order to find both "1 vulnerability" and "X vulnerabilities"
            find_element(:vulnerability_report_grouped).has_content?("detected #{expected} vulnerabilit")
          end

          def num_approvals_required
            approvals_content.match(/Requires (\d+) more approvals/)[1].to_i
          end

          private

          def approvals_content
            # The approvals widget displays "Checking approval status" briefly
            # while loading the widget, so before returning the text we wait
            # for it to include terms from content we expect. The kinds
            # of content we expect are:
            #
            # * Requires X more approvals from Quality, UX, and frontend.
            # * Merge request approved
            #
            # It can also briefly display cached data while loading so we
            # wait for it to update first
            sleep 1

            text = nil
            wait(reload: false) do
              text = find_element(:approvals_summary_content).text
              text =~ /Requires|approved/
            end

            text
          end
        end
      end
    end
  end
end
