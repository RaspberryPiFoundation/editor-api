# frozen_string_literal: true

class EditorApiSchema < GraphQL::Schema
  mutation Types::MutationType
  query Types::QueryType

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader

  # Prevent overly-complex queries
  max_complexity 500

  # Prevent deeply-nested queries
  max_depth 100

  # Stop validating when it encounters this many errors:
  validate_max_errors 100

  default_max_page_size 10

  # GraphQL-Ruby calls this when something goes wrong while running a query:
  # def self.type_error(err, context)
  # # if err.is_a?(GraphQL::InvalidNullError)
  # #   # report to your bug tracker here
  # #   return nil
  # # end
  #  super
  # end

  # Union and Interface Resolution
  def self.resolve_type(_abstract_type, obj, _ctx)
    case obj
    when Project
      Types::ProjectType
    when Component
      Types::ComponentType
    else
      raise EditorApiError::GraphqlValidationFailed,
            "Unexpected object: #{obj}"
    end
  end

  def self.unauthorized_object(error)
    # Add a top-level error to the response instead of returning nil:
    raise EditorApiError::Forbidden,
          "An object of type #{error.type.graphql_name} was hidden due to permissions"
  end

  def self.unauthorized_field(error)
    # Add a top-level error to the response instead of returning nil:
    raise EditorApiError::Forbidden,
          "The field #{error.field.graphql_name} on " \
          "an object of type #{error.type.graphql_name} was hidden due to permissions"
  end

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
