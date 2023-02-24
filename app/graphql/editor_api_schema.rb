# frozen_string_literal: true

class EditorApiSchema < GraphQL::Schema
  mutation Types::MutationType
  query Types::QueryType

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader

  # GraphQL-Ruby calls this when something goes wrong while running a query:

  # Union and Interface Resolution
  def self.resolve_type(_abstract_type, obj, _ctx)
    case obj
    when Project
      Types::ProjectType
    when Component
      Types::ComponentType
    else
      raise("Unexpected object: #{obj}")
    end
  end

  def self.unauthorized_object(error)
    # Add a top-level error to the response instead of returning nil:
    raise GraphQL::ExecutionError, "An object of type #{error.type.graphql_name} was hidden due to permissions"
  end

  def self.unauthorized_field(error)
    # Add a top-level error to the response instead of returning nil:
    raise GraphQL::ExecutionError,
          "The field #{error.field.graphql_name} on " \
          "an object of type #{error.type.graphql_name} was hidden due to permissions"
  end

  # Stop validating when it encounters this many errors:
  validate_max_errors 100
  default_max_page_size 10

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, _type_definition, _query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    object.to_gid_param
  end

  # Given a string UUID, find the object
  def self.object_from_id(global_id, _query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    GlobalID.find(global_id)
  end
end
