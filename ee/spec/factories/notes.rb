# frozen_string_literal: true

FactoryBot.modify do
  factory :note do
    trait :on_epic do
      noteable { create(:epic) }
      project nil
    end

    trait :with_review do
      review
    end
  end
end

FactoryBot.define do
  factory :note_on_epic, parent: :note, traits: [:on_epic]

  factory :diff_note_on_design, class: DiffNote do
    association :project
    note { generate(:title) }
    author { project&.creator || create(:user) }

    noteable { create(:design, :with_file, project: project) }

    position do
      Gitlab::Diff::Position.new(
        old_path: noteable.full_path,
        new_path: noteable.full_path,
        width: 10,
        height: 10,
        x: 1,
        y: 1,
        position_type: "image",
        diff_refs: noteable.diff_refs
      )
    end
  end
end
