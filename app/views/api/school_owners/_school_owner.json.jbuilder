# frozen_string_literal: true

json.call(
  owner,
  :id,
  :name
)

json.type(owner.type) if owner.respond_to?(:type)

include_email = local_assigns.fetch(:include_email, true)

json.email(owner.email) if include_email
