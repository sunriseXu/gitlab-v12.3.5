# frozen_string_literal: true

module EE
  module ProtectedBranches
    module Loggable
      def log_audit_event(protected_branch_service, action)
        if protected_branch_service.errors.blank?
          ::EE::AuditEvents::ProtectedBranchAuditEventService
            .new(current_user, protected_branch_service, action)
            .security_event
        end
      end
    end
  end
end
