# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :project_scope

  def project_scope
    super || Project
  end
end
