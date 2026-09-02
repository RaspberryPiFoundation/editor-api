# frozen_string_literal: true

class BackfillInstructionStepsFromInstructions < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE projects
      SET instruction_steps = to_jsonb(instructions)
      WHERE instruction_steps IS NULL AND instructions IS NOT NULL
    SQL
  end

  def down
  end
end
