# frozen_string_literal: true

module Types
  class EpicType < BaseObject
    graphql_name 'Epic'

    authorize :read_epic

    expose_permissions Types::PermissionTypes::Epic

    present_using EpicPresenter

    implements(Types::Notes::NoteableType)

    field :id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :iid, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :title, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :description, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :state, EpicStateEnum, null: false # rubocop:disable Graphql/Descriptions

    field :group, GroupType, # rubocop:disable Graphql/Descriptions
          null: false,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, obj.group_id).find }
    field :parent, EpicType, # rubocop:disable Graphql/Descriptions
          null: true,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Epic, obj.parent_id).find }
    field :author, Types::UserType, # rubocop:disable Graphql/Descriptions
          null: false,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, obj.author_id).find }

    field :start_date, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions
    field :start_date_is_fixed, GraphQL::BOOLEAN_TYPE, null: true, method: :start_date_is_fixed?, authorize: :admin_epic # rubocop:disable Graphql/Descriptions
    field :start_date_fixed, Types::TimeType, null: true, authorize: :admin_epic # rubocop:disable Graphql/Descriptions
    field :start_date_from_milestones, Types::TimeType, null: true, authorize: :admin_epic # rubocop:disable Graphql/Descriptions

    field :due_date, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions
    field :due_date_is_fixed, GraphQL::BOOLEAN_TYPE, null: true, method: :due_date_is_fixed?, authorize: :admin_epic # rubocop:disable Graphql/Descriptions
    field :due_date_fixed, Types::TimeType, null: true, authorize: :admin_epic # rubocop:disable Graphql/Descriptions
    field :due_date_from_milestones, Types::TimeType, null: true, authorize: :admin_epic # rubocop:disable Graphql/Descriptions

    field :closed_at, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions
    field :created_at, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions
    field :updated_at, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions

    field :children, # rubocop:disable Graphql/Descriptions
          ::Types::EpicType.connection_type,
          null: true,
          resolver: ::Resolvers::EpicResolver

    field :has_children, GraphQL::BOOLEAN_TYPE, null: false, method: :has_children? # rubocop:disable Graphql/Descriptions
    field :has_issues, GraphQL::BOOLEAN_TYPE, null: false, method: :has_issues? # rubocop:disable Graphql/Descriptions

    field :web_path, GraphQL::STRING_TYPE, null: false, method: :group_epic_path # rubocop:disable Graphql/Descriptions
    field :web_url, GraphQL::STRING_TYPE, null: false, method: :group_epic_url # rubocop:disable Graphql/Descriptions
    field :relative_position, GraphQL::INT_TYPE, null: true, description: 'The relative position of the epic in the Epic tree'
    field :relation_path, GraphQL::STRING_TYPE, null: true, method: :group_epic_link_path # rubocop:disable Graphql/Descriptions
    field :reference, GraphQL::STRING_TYPE, null: false, method: :epic_reference do # rubocop:disable Graphql/Descriptions
      argument :full, GraphQL::BOOLEAN_TYPE, required: false, default_value: false # rubocop:disable Graphql/Descriptions
    end

    field :issues, # rubocop:disable Graphql/Descriptions
          Types::EpicIssueType.connection_type,
          null: true,
          resolver: Resolvers::EpicIssuesResolver
  end
end
