# frozen_string_literal: true

class MakeProjectIdentifierNonNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null(:projects, :identifier, false)
  end
end
