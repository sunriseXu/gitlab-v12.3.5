# frozen_string_literal: true

module EE
  module Issuable
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    class_methods do
      def labels_hash
        issue_labels = Hash.new { |h, k| h[k] = [] }

        relation = unscoped.where(id: self.select(:id)).eager_load(:labels)
        relation.pluck(:id, 'labels.title').each do |issue_id, label|
          issue_labels[issue_id] << label
        end

        issue_labels
      end
    end

    override :milestone_available?
    def milestone_available?
      return true if is_a?(Epic)

      super
    end

    override :supports_milestone?
    def supports_milestone?
      super && !is_a?(Epic)
    end

    def supports_epic?
      is_a?(Issue) && project.group
    end
  end
end
