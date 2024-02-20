# frozen_string_literal: true

Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
Rails.application.config.active_storage.replace_on_assign_to_many = false
